package garethpaul.com.fridge;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.nio.file.Files;
import java.nio.file.attribute.PosixFilePermission;

public final class ItemStoreHostTest {
    public static void main(String[] args) throws Exception {
        ItemStoreHostTest test = new ItemStoreHostTest();
        test.roundTripsUtf8WithOwnerOnlyPermissions();
        test.rejectsMalformedUtf8();
        test.rejectsCarriageReturnBoundariesAndOversizedLines();
        test.rejectsControlCharactersAndOversizedCollections();
        test.rejectsSymlinkedStorageFiles();
        test.recoversVerifiedBackupWhenTargetIsCorrupt();
        test.preservesCorruptTargetWhenBackupIsAlsoInvalid();
        test.preservesLiveModelUntilPersistenceCommits();
        test.serializesConcurrentModelMutations();
    }

    private void roundTripsUtf8WithOwnerOnlyPermissions() throws Exception {
        File root = temporaryDirectory("roundtrip");
        try {
            ItemStore store = new ItemStore(root);
            store.write(Arrays.asList("milk", "café", "🥛"));
            assertEquals(Arrays.asList("milk", "café", "🥛"), store.read());
            File target = new File(root, "food.txt");
            assertTrue(target.isFile(), "target should be a regular file");
            assertTrue(target.canRead(), "target should remain owner-readable");
            assertTrue(target.canWrite(), "target should remain owner-writable");
            if (Files.getFileStore(target.toPath()).supportsFileAttributeView("posix")) {
                Set<PosixFilePermission> permissions = Files.getPosixFilePermissions(target.toPath());
                assertFalse(permissions.contains(PosixFilePermission.GROUP_READ), "group read must be disabled");
                assertFalse(permissions.contains(PosixFilePermission.GROUP_WRITE), "group write must be disabled");
                assertFalse(permissions.contains(PosixFilePermission.OTHERS_READ), "other read must be disabled");
                assertFalse(permissions.contains(PosixFilePermission.OTHERS_WRITE), "other write must be disabled");
            }
        } finally {
            deleteTree(root);
        }
    }

    private void rejectsMalformedUtf8() throws Exception {
        final File root = temporaryDirectory("malformed");
        try {
            writeBytes(new File(root, "food.txt"), new byte[] {(byte) 0xC3, (byte) 0x28, '\n'});
            expectIOException(new CheckedRunnable() {
                @Override
                public void run() throws Exception {
                    new ItemStore(root).read();
                }
            });
        } finally {
            deleteTree(root);
        }
    }

    private void rejectsCarriageReturnBoundariesAndOversizedLines() throws Exception {
        final File carriageReturnRoot = temporaryDirectory("carriage-return");
        final File oversizedLineRoot = temporaryDirectory("oversized-line");
        try {
            writeBytes(new File(carriageReturnRoot, "food.txt"), "milk\reggs\n".getBytes("UTF-8"));
            expectIOException(new CheckedRunnable() {
                @Override
                public void run() throws Exception {
                    new ItemStore(carriageReturnRoot).read();
                }
            });

            byte[] oversized = new byte[ItemPolicy.MAX_ITEM_BYTES + 2];
            Arrays.fill(oversized, (byte) 'a');
            oversized[oversized.length - 1] = '\n';
            writeBytes(new File(oversizedLineRoot, "food.txt"), oversized);
            expectIOException(new CheckedRunnable() {
                @Override
                public void run() throws Exception {
                    new ItemStore(oversizedLineRoot).read();
                }
            });
        } finally {
            deleteTree(carriageReturnRoot);
            deleteTree(oversizedLineRoot);
        }
    }

    private void rejectsControlCharactersAndOversizedCollections() throws Exception {
        assertNull(ItemPolicy.normalizeInput("milk\u0000eggs"));
        assertNull(ItemPolicy.normalizeInput("safe\u202Etxt"));

        final ArrayList<String> tooMany = new ArrayList<String>();
        for (int index = 0; index < 513; index++) {
            tooMany.add("item-" + index);
        }
        expectIOException(new CheckedRunnable() {
            @Override
            public void run() throws Exception {
                ItemPolicy.validateItems(tooMany);
            }
        });
    }

    private void rejectsSymlinkedStorageFiles() throws Exception {
        final File root = temporaryDirectory("symlink");
        File outside = File.createTempFile("fridge-outside", ".txt");
        try {
            writeBytes(outside, "private\n".getBytes("UTF-8"));
            java.nio.file.Files.createSymbolicLink(
                    new File(root, "food.txt").toPath(),
                    outside.toPath());
            expectIOException(new CheckedRunnable() {
                @Override
                public void run() throws Exception {
                    new ItemStore(root).read();
                }
            });
            assertEquals("private\n", new String(readBytes(outside), "UTF-8"));
        } finally {
            deleteTree(root);
            outside.delete();
        }
    }

    private void recoversVerifiedBackupWhenTargetIsCorrupt() throws Exception {
        File root = temporaryDirectory("backup");
        try {
            writeBytes(new File(root, "food.txt"), new byte[] {(byte) 0xC3, (byte) 0x28});
            writeBytes(new File(root, "food.txt.bak"), "milk\n".getBytes("UTF-8"));
            assertEquals(Arrays.asList("milk"), new ItemStore(root).read());
            assertFalse(new File(root, "food.txt.bak").exists(), "backup should be consumed");
        } finally {
            deleteTree(root);
        }
    }

    private void preservesCorruptTargetWhenBackupIsAlsoInvalid() throws Exception {
        final File root = temporaryDirectory("invalid-backup");
        try {
            byte[] targetBytes = new byte[] {(byte) 0xC3, (byte) 0x28};
            writeBytes(new File(root, "food.txt"), targetBytes);
            writeBytes(new File(root, "food.txt.bak"), new byte[] {0, '\n'});
            expectIOException(new CheckedRunnable() {
                @Override
                public void run() throws Exception {
                    new ItemStore(root).read();
                }
            });
            assertArrayEquals(targetBytes, readBytes(new File(root, "food.txt")));
        } finally {
            deleteTree(root);
        }
    }

    private void preservesLiveModelUntilPersistenceCommits() {
        final ArrayList<String> items = new ArrayList<String>(Arrays.asList("milk"));
        ItemListTransaction transaction = new ItemListTransaction();
        ItemListTransaction.Result result = transaction.add(
                items,
                "eggs",
                new ItemListTransaction.Persistence() {
                    @Override
                    public boolean persist(List<String> proposedItems) {
                        assertEquals(Arrays.asList("milk"), items);
                        assertEquals(Arrays.asList("milk", "eggs"), proposedItems);
                        return true;
                    }
                });
        assertEquals(ItemListTransaction.Result.COMMITTED, result);
        assertEquals(Arrays.asList("milk", "eggs"), items);
    }

    private void serializesConcurrentModelMutations() throws Exception {
        final ArrayList<String> items = new ArrayList<String>(Arrays.asList("milk"));
        final Object enteredPersistence = new Object();
        final boolean[] entered = {false};
        final boolean[] release = {false};
        Thread transactionThread = new Thread(new Runnable() {
            @Override
            public void run() {
                new ItemListTransaction().add(items, "eggs", new ItemListTransaction.Persistence() {
                    @Override
                    public boolean persist(List<String> proposedItems) {
                        synchronized (enteredPersistence) {
                            entered[0] = true;
                            enteredPersistence.notifyAll();
                            while (!release[0]) {
                                try {
                                    enteredPersistence.wait();
                                } catch (InterruptedException error) {
                                    throw new AssertionError(error);
                                }
                            }
                        }
                        return true;
                    }
                });
            }
        });
        transactionThread.start();
        synchronized (enteredPersistence) {
            while (!entered[0]) {
                enteredPersistence.wait();
            }
        }
        Thread competingMutation = new Thread(new Runnable() {
            @Override
            public void run() {
                synchronized (items) {
                    items.add("cheese");
                }
            }
        });
        competingMutation.start();
        Thread.sleep(50L);
        assertTrue(competingMutation.isAlive(), "competing mutation should wait for transaction ownership");
        synchronized (enteredPersistence) {
            release[0] = true;
            enteredPersistence.notifyAll();
        }
        transactionThread.join(2000L);
        competingMutation.join(2000L);
        assertEquals(Arrays.asList("milk", "eggs", "cheese"), items);
    }

    private File temporaryDirectory(String name) throws IOException {
        File file = File.createTempFile("fridge-" + name, "");
        if (!file.delete() || !file.mkdir()) {
            throw new IOException("Unable to create test directory");
        }
        return file;
    }

    private void writeBytes(File file, byte[] bytes) throws IOException {
        FileOutputStream stream = new FileOutputStream(file);
        try {
            stream.write(bytes);
        } finally {
            stream.close();
        }
    }

    private byte[] readBytes(File file) throws IOException {
        FileInputStreamCompat stream = new FileInputStreamCompat(file);
        try {
            return stream.readAll();
        } finally {
            stream.close();
        }
    }

    private void expectIOException(CheckedRunnable runnable) throws Exception {
        try {
            runnable.run();
            throw new AssertionError("Expected IOException");
        } catch (IOException expected) {
        }
    }

    private void deleteTree(File file) {
        if (file == null || !file.exists()) {
            return;
        }
        if (file.isDirectory() && !java.nio.file.Files.isSymbolicLink(file.toPath())) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteTree(child);
                }
            }
        }
        file.delete();
    }

    private static void assertEquals(Object expected, Object actual) {
        if (!expected.equals(actual)) {
            throw new AssertionError("Expected " + expected + " but was " + actual);
        }
    }

    private static void assertTrue(boolean value, String message) {
        if (!value) {
            throw new AssertionError(message);
        }
    }

    private static void assertFalse(boolean value, String message) {
        assertTrue(!value, message);
    }

    private static void assertNull(Object value) {
        if (value != null) {
            throw new AssertionError("Expected null but was " + value);
        }
    }

    private static void assertArrayEquals(byte[] expected, byte[] actual) {
        if (!Arrays.equals(expected, actual)) {
            throw new AssertionError("Byte arrays differ");
        }
    }

    private interface CheckedRunnable {
        void run() throws Exception;
    }
}
