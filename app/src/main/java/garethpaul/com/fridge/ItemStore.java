package garethpaul.com.fridge;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CodingErrorAction;
import java.util.ArrayList;
import java.util.List;

final class ItemStore {
    interface FilePermissions {
        void harden(File file) throws IOException;
    }

    private static final FilePermissions OWNER_ONLY_PERMISSIONS = new FilePermissions() {
        @Override
        public void harden(File file) throws IOException {
            if (!file.setReadable(false, false)
                    || !file.setWritable(false, false)
                    || !file.setExecutable(false, false)
                    || !file.setReadable(true, true)
                    || !file.setWritable(true, true)) {
                throw new IOException("Unable to restrict fridge storage permissions");
            }
        }
    };

    private static final Charset UTF_8 = Charset.forName("UTF-8");
    private static final String TARGET_NAME = "food.txt";
    private static final String TEMPORARY_NAME = "food.txt.tmp";
    private static final String BACKUP_NAME = "food.txt.bak";

    private final File root;
    private final File target;
    private final File temporary;
    private final File backup;
    private final FilePermissions filePermissions;

    ItemStore(File filesDirectory) throws IOException {
        this(filesDirectory, OWNER_ONLY_PERMISSIONS);
    }

    ItemStore(File filesDirectory, FilePermissions filePermissions) throws IOException {
        if (filesDirectory == null || !filesDirectory.isDirectory()) {
            throw new IOException("Fridge storage directory unavailable");
        }
        root = filesDirectory.getCanonicalFile();
        target = child(TARGET_NAME);
        temporary = child(TEMPORARY_NAME);
        backup = child(BACKUP_NAME);
        this.filePermissions = filePermissions;
    }

    ArrayList<String> read() throws IOException {
        requireSafeExistingFile(target);
        requireSafeExistingFile(backup);
        requireSafeExistingFile(temporary);

        if (!target.exists() && backup.exists() && !backup.renameTo(target)) {
            throw new IOException("Unable to restore fridge backup");
        }

        if (!target.exists()) {
            removeStaleTemporary();
            return new ArrayList<String>();
        }

        try {
            ArrayList<String> items = readFile(target);
            removeIfPresent(backup);
            removeStaleTemporary();
            hardenPermissions(target);
            return items;
        } catch (IOException targetError) {
            if (!backup.exists()) {
                throw targetError;
            }
            ArrayList<String> recoveredItems = readFile(backup);
            recoverBackupOverInvalidTarget();
            removeStaleTemporary();
            hardenPermissions(target);
            return recoveredItems;
        }
    }

    void write(List<String> items) throws IOException {
        ItemPolicy.validateItems(items);
        requireSafeExistingFile(target);
        requireSafeExistingFile(backup);
        requireSafeExistingFile(temporary);
        removeIfPresent(temporary);

        writeTemporary(items);
        ItemFileTransaction.Result result = new ItemFileTransaction().replace(
                temporary,
                target,
                backup);
        if (result != ItemFileTransaction.Result.INSTALLED) {
            if (result != ItemFileTransaction.Result.FAILED_PRESERVE_TEMPORARY) {
                removeIfPresent(temporary);
            }
            throw new IOException("Unable to replace fridge item file");
        }
    }

    private File child(String name) throws IOException {
        File file = new File(root, name).getAbsoluteFile();
        if (!root.equals(file.getParentFile().getCanonicalFile())) {
            throw new IOException("Unsafe fridge storage path");
        }
        return file;
    }

    private void requireSafeExistingFile(File file) throws IOException {
        if (!file.exists()) {
            return;
        }
        if (!file.isFile() || !file.getAbsoluteFile().equals(file.getCanonicalFile())) {
            throw new IOException("Unsafe fridge storage file");
        }
    }

    private ArrayList<String> readFile(File file) throws IOException {
        if (file.length() > ItemPolicy.MAX_FILE_BYTES) {
            throw new IOException("Fridge item file is too large");
        }

        CharsetDecoder decoder = UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT);
        ArrayList<String> items = new ArrayList<String>();
        BoundedInputStream boundedStream = new BoundedInputStream(
                new FileInputStream(file),
                ItemPolicy.MAX_FILE_BYTES);
        Reader reader = new InputStreamReader(boundedStream, decoder);
        IOException failure = null;
        try {
            StringBuilder item = new StringBuilder();
            int character;
            while ((character = reader.read()) != -1) {
                if (character == '\n') {
                    addItem(items, item);
                    item.setLength(0);
                } else {
                    item.append((char) character);
                    if (item.length() > ItemPolicy.MAX_ITEM_BYTES) {
                        throw new IOException("Fridge item is too long");
                    }
                }
            }
            if (boundedStream.exceededLimit()) {
                throw new IOException("Fridge item file is too large");
            }
            if (item.length() > 0) {
                addItem(items, item);
            }
            ItemPolicy.validateItems(items);
            return items;
        } catch (IOException error) {
            failure = error;
            throw error;
        } finally {
            try {
                reader.close();
            } catch (IOException closeError) {
                if (failure == null) {
                    throw closeError;
                }
            }
        }
    }

    private void addItem(ArrayList<String> items, StringBuilder item) throws IOException {
        String value = item.toString();
        if (!ItemPolicy.isValidItem(value)) {
            throw new IOException("Invalid fridge item");
        }
        items.add(value);
        if (items.size() > ItemPolicy.MAX_ITEMS) {
            throw new IOException("Too many fridge items");
        }
    }

    private void writeTemporary(List<String> items) throws IOException {
        FileOutputStream stream = new FileOutputStream(temporary, false);
        IOException failure = null;
        try {
            hardenPermissions(temporary);
            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(stream, UTF_8));
            for (String item : items) {
                writer.write(item);
                writer.write('\n');
            }
            writer.flush();
            stream.getFD().sync();
        } catch (IOException error) {
            failure = error;
            throw error;
        } finally {
            try {
                stream.close();
            } catch (IOException closeError) {
                if (failure == null) {
                    throw closeError;
                }
            }
        }
        if (temporary.length() > ItemPolicy.MAX_FILE_BYTES) {
            throw new IOException("Fridge item file is too large");
        }
    }

    private void recoverBackupOverInvalidTarget() throws IOException {
        removeIfPresent(temporary);
        if (!target.renameTo(temporary)) {
            throw new IOException("Unable to preserve invalid fridge item file");
        }
        if (backup.renameTo(target)) {
            removeIfPresent(temporary);
            return;
        }
        temporary.renameTo(target);
        throw new IOException("Unable to restore valid fridge backup");
    }

    private void removeStaleTemporary() throws IOException {
        removeIfPresent(temporary);
    }

    private void removeIfPresent(File file) throws IOException {
        if (file.exists() && !file.delete()) {
            throw new IOException("Unable to remove stale fridge storage file");
        }
    }

    private void hardenPermissions(File file) throws IOException {
        filePermissions.harden(file);
    }

    private static final class BoundedInputStream extends InputStream {
        private final InputStream input;
        private final long limit;
        private long count;
        private boolean exceeded;

        BoundedInputStream(InputStream input, long limit) {
            this.input = input;
            this.limit = limit;
        }

        @Override
        public int read() throws IOException {
            if (count > limit) {
                exceeded = true;
                return -1;
            }
            int value = input.read();
            if (value != -1) {
                count += 1;
                if (count > limit) {
                    exceeded = true;
                }
            }
            return value;
        }

        @Override
        public int read(byte[] buffer, int offset, int length) throws IOException {
            if (count > limit) {
                exceeded = true;
                return -1;
            }
            int allowed = (int) Math.min((long) length, limit - count + 1L);
            int read = input.read(buffer, offset, allowed);
            if (read > 0) {
                count += read;
                if (count > limit) {
                    exceeded = true;
                }
            }
            return read;
        }

        @Override
        public void close() throws IOException {
            input.close();
        }

        boolean exceededLimit() {
            return exceeded;
        }
    }
}
