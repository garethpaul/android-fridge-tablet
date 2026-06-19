package garethpaul.com.fridge;

import java.io.File;

final class ItemFileTransaction {
    enum Result {
        INSTALLED,
        FAILED,
        FAILED_PRESERVE_TEMPORARY
    }

    interface FileOperations {
        boolean exists(File file);

        boolean delete(File file);

        boolean rename(File source, File destination);
    }

    private static final FileOperations REAL_FILES = new FileOperations() {
        @Override
        public boolean exists(File file) {
            return file.exists();
        }

        @Override
        public boolean delete(File file) {
            return file.delete();
        }

        @Override
        public boolean rename(File source, File destination) {
            return source.renameTo(destination);
        }
    };

    private final FileOperations files;

    ItemFileTransaction() {
        this(REAL_FILES);
    }

    ItemFileTransaction(FileOperations files) {
        this.files = files;
    }

    Result replace(File temporaryFile, File targetFile, File backupFile) {
        if (files.exists(backupFile) && !files.delete(backupFile)) {
            return Result.FAILED;
        }

        boolean hadTarget = files.exists(targetFile);
        if (hadTarget && !files.rename(targetFile, backupFile)) {
            return Result.FAILED;
        }

        if (files.rename(temporaryFile, targetFile)) {
            return Result.INSTALLED;
        }

        if (!hadTarget || files.rename(backupFile, targetFile)) {
            return Result.FAILED;
        }

        return Result.FAILED_PRESERVE_TEMPORARY;
    }

    boolean restoreBackup(File targetFile, File backupFile) {
        if (files.exists(targetFile) || !files.exists(backupFile)) {
            return true;
        }
        return files.rename(backupFile, targetFile);
    }
}
