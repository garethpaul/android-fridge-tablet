package garethpaul.com.fridge;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.util.HashSet;
import java.util.Set;

import org.junit.Test;

public class ItemFileTransactionTest {
    private final File temporaryFile = new File("food.txt.tmp");
    private final File targetFile = new File("food.txt");
    private final File backupFile = new File("food.txt.bak");

    @Test
    public void installsFirstItemFile() {
        FakeFiles files = new FakeFiles(temporaryFile);

        ItemFileTransaction.Result result = transaction(files).replace(
                temporaryFile,
                targetFile,
                backupFile);

        assertEquals(ItemFileTransaction.Result.INSTALLED, result);
        files.assertPresent(targetFile);
        files.assertAbsent(temporaryFile, backupFile);
    }

    @Test
    public void replacesExistingItemFileAndRemovesBackup() {
        FakeFiles files = new FakeFiles(temporaryFile, targetFile);

        ItemFileTransaction.Result result = transaction(files).replace(
                temporaryFile,
                targetFile,
                backupFile);

        assertEquals(ItemFileTransaction.Result.INSTALLED, result);
        files.assertPresent(targetFile);
        files.assertAbsent(temporaryFile, backupFile);
    }

    @Test
    public void restoresExistingItemFileWhenInstallationFails() {
        FakeFiles files = new FakeFiles(temporaryFile, targetFile);
        files.failRename(temporaryFile, targetFile);

        ItemFileTransaction.Result result = transaction(files).replace(
                temporaryFile,
                targetFile,
                backupFile);

        assertEquals(ItemFileTransaction.Result.FAILED, result);
        files.assertPresent(temporaryFile, targetFile);
        files.assertAbsent(backupFile);
    }

    @Test
    public void preservesTemporaryAndBackupFilesWhenRollbackFails() {
        FakeFiles files = new FakeFiles(temporaryFile, targetFile);
        files.failRename(temporaryFile, targetFile);
        files.failRename(backupFile, targetFile);

        ItemFileTransaction.Result result = transaction(files).replace(
                temporaryFile,
                targetFile,
                backupFile);

        assertEquals(ItemFileTransaction.Result.FAILED_PRESERVE_TEMPORARY, result);
        files.assertPresent(temporaryFile, backupFile);
        files.assertAbsent(targetFile);
    }

    @Test
    public void refusesToTouchCurrentFileWhenStaleBackupCannotBeRemoved() {
        FakeFiles files = new FakeFiles(temporaryFile, targetFile, backupFile);
        files.failDelete(backupFile);

        ItemFileTransaction.Result result = transaction(files).replace(
                temporaryFile,
                targetFile,
                backupFile);

        assertEquals(ItemFileTransaction.Result.FAILED, result);
        files.assertPresent(temporaryFile, targetFile, backupFile);
    }

    @Test
    public void successfulInstallSurvivesBackupCleanupFailure() {
        FakeFiles files = new FakeFiles(temporaryFile, targetFile);
        files.failDelete(backupFile);

        ItemFileTransaction.Result result = transaction(files).replace(
                temporaryFile,
                targetFile,
                backupFile);

        assertEquals(ItemFileTransaction.Result.INSTALLED, result);
        files.assertPresent(targetFile, backupFile);
        files.assertAbsent(temporaryFile);
    }

    @Test
    public void restoresBackupWhenCanonicalFileIsMissing() {
        FakeFiles files = new FakeFiles(backupFile);

        boolean restored = transaction(files).restoreBackup(targetFile, backupFile);

        assertTrue(restored);
        files.assertPresent(targetFile);
        files.assertAbsent(backupFile);
    }

    @Test
    public void preservesBackupWhenStartupRecoveryFails() {
        FakeFiles files = new FakeFiles(backupFile);
        files.failRename(backupFile, targetFile);

        boolean restored = transaction(files).restoreBackup(targetFile, backupFile);

        assertFalse(restored);
        files.assertPresent(backupFile);
        files.assertAbsent(targetFile);
    }

    private ItemFileTransaction transaction(FakeFiles files) {
        return new ItemFileTransaction(files);
    }

    private static final class FakeFiles implements ItemFileTransaction.FileOperations {
        private final Set<String> present = new HashSet<String>();
        private final Set<String> failedDeletes = new HashSet<String>();
        private final Set<String> failedRenames = new HashSet<String>();

        FakeFiles(File... files) {
            for (File file : files) {
                present.add(file.getPath());
            }
        }

        void failDelete(File file) {
            failedDeletes.add(file.getPath());
        }

        void failRename(File source, File destination) {
            failedRenames.add(renameKey(source, destination));
        }

        void assertPresent(File... files) {
            for (File file : files) {
                assertTrue(file.getPath() + " should exist", exists(file));
            }
        }

        void assertAbsent(File... files) {
            for (File file : files) {
                assertFalse(file.getPath() + " should not exist", exists(file));
            }
        }

        @Override
        public boolean exists(File file) {
            return present.contains(file.getPath());
        }

        @Override
        public boolean delete(File file) {
            if (failedDeletes.contains(file.getPath())) {
                return false;
            }
            return present.remove(file.getPath());
        }

        @Override
        public boolean rename(File source, File destination) {
            if (failedRenames.contains(renameKey(source, destination)) || !exists(source)) {
                return false;
            }
            present.remove(source.getPath());
            present.add(destination.getPath());
            return true;
        }

        private String renameKey(File source, File destination) {
            return source.getPath() + " -> " + destination.getPath();
        }
    }
}
