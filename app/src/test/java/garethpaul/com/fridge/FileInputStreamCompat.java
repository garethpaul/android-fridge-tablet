package garethpaul.com.fridge;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

final class FileInputStreamCompat extends FileInputStream {
    FileInputStreamCompat(File file) throws IOException {
        super(file);
    }

    byte[] readAll() throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int count;
        while ((count = read(buffer)) != -1) {
            output.write(buffer, 0, count);
        }
        return output.toByteArray();
    }
}
