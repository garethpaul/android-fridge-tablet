package garethpaul.com.fridge;

import android.test.AndroidTestCase;

import java.io.File;
import java.util.Arrays;

public class ItemStoreInstrumentationTest extends AndroidTestCase {
    public void testInternalStorageRoundTripAndRecoveryFilesStayPrivate() throws Exception {
        File root = getContext().getFilesDir();
        ItemStore store = new ItemStore(root);
        store.write(Arrays.asList("milk", "eggs"));

        assertEquals(Arrays.asList("milk", "eggs"), store.read());
        assertTrue(new File(root, "food.txt").isFile());
        assertFalse(new File(root, "food.txt.tmp").exists());
        assertFalse(new File(root, "food.txt.bak").exists());
    }
}
