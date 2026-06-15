package garethpaul.com.fridge;

import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.fail;

public class ItemListTransactionTest {
    private final ItemListTransaction transaction = new ItemListTransaction();

    @Test
    public void keepsAddedItemWhenPersistenceSucceeds() {
        ArrayList<String> items = items("milk");
        RecordingPersistence persistence = new RecordingPersistence(items, true);

        ItemListTransaction.Result result = transaction.add(items, "eggs", persistence);

        assertEquals(ItemListTransaction.Result.COMMITTED, result);
        assertEquals(Arrays.asList("milk", "eggs"), items);
        assertEquals(Arrays.asList("milk", "eggs"), persistence.observedItems);
        assertEquals(1, persistence.calls);
    }

    @Test
    public void restoresListWhenAddedItemCannotPersist() {
        ArrayList<String> items = items("milk");
        RecordingPersistence persistence = new RecordingPersistence(items, false);

        ItemListTransaction.Result result = transaction.add(items, "eggs", persistence);

        assertEquals(ItemListTransaction.Result.ROLLED_BACK, result);
        assertEquals(Arrays.asList("milk"), items);
        assertEquals(Arrays.asList("milk", "eggs"), persistence.observedItems);
        assertEquals(1, persistence.calls);
    }

    @Test
    public void restoresListBeforeRethrowingAddPersistenceException() {
        ArrayList<String> items = items("milk");
        RuntimeException expected = new IllegalStateException("write failed");
        ThrowingPersistence persistence = new ThrowingPersistence(items, expected);

        try {
            transaction.add(items, "eggs", persistence);
            fail("Expected persistence exception");
        } catch (RuntimeException actual) {
            assertSame(expected, actual);
        }

        assertEquals(Arrays.asList("milk"), items);
        assertEquals(Arrays.asList("milk", "eggs"), persistence.observedItems);
        assertEquals(1, persistence.calls);
    }

    @Test
    public void keepsRemovalWhenPersistenceSucceeds() {
        ArrayList<String> items = items("milk", "eggs", "cheese");
        RecordingPersistence persistence = new RecordingPersistence(items, true);

        ItemListTransaction.Result result = transaction.remove(items, 1, persistence);

        assertEquals(ItemListTransaction.Result.COMMITTED, result);
        assertEquals(Arrays.asList("milk", "cheese"), items);
        assertEquals(Arrays.asList("milk", "cheese"), persistence.observedItems);
        assertEquals(1, persistence.calls);
    }

    @Test
    public void restoresRemovedItemAtOriginalPositionWhenPersistenceFails() {
        ArrayList<String> items = items("milk", "eggs", "cheese");
        RecordingPersistence persistence = new RecordingPersistence(items, false);

        ItemListTransaction.Result result = transaction.remove(items, 1, persistence);

        assertEquals(ItemListTransaction.Result.ROLLED_BACK, result);
        assertEquals(Arrays.asList("milk", "eggs", "cheese"), items);
        assertEquals(Arrays.asList("milk", "cheese"), persistence.observedItems);
        assertEquals(1, persistence.calls);
    }

    @Test
    public void restoresRemovedItemBeforeRethrowingPersistenceException() {
        ArrayList<String> items = items("milk", "eggs", "cheese");
        RuntimeException expected = new IllegalStateException("write failed");
        ThrowingPersistence persistence = new ThrowingPersistence(items, expected);

        try {
            transaction.remove(items, 1, persistence);
            fail("Expected persistence exception");
        } catch (RuntimeException actual) {
            assertSame(expected, actual);
        }

        assertEquals(Arrays.asList("milk", "eggs", "cheese"), items);
        assertEquals(Arrays.asList("milk", "cheese"), persistence.observedItems);
        assertEquals(1, persistence.calls);
    }

    @Test
    public void supportsRemovingFirstAndLastItems() {
        ArrayList<String> firstItems = items("milk", "eggs", "cheese");
        ArrayList<String> lastItems = items("milk", "eggs", "cheese");

        transaction.remove(firstItems, 0, new RecordingPersistence(firstItems, true));
        transaction.remove(lastItems, 2, new RecordingPersistence(lastItems, true));

        assertEquals(Arrays.asList("eggs", "cheese"), firstItems);
        assertEquals(Arrays.asList("milk", "eggs"), lastItems);
    }

    @Test
    public void ignoresInvalidRemovalPositionsWithoutPersisting() {
        ArrayList<String> items = items("milk", "eggs");
        RecordingPersistence persistence = new RecordingPersistence(items, true);

        ItemListTransaction.Result negative = transaction.remove(items, -1, persistence);
        ItemListTransaction.Result pastEnd = transaction.remove(items, items.size(), persistence);

        assertEquals(ItemListTransaction.Result.UNCHANGED, negative);
        assertEquals(ItemListTransaction.Result.UNCHANGED, pastEnd);
        assertEquals(Arrays.asList("milk", "eggs"), items);
        assertEquals(0, persistence.calls);
    }

    private ArrayList<String> items(String... values) {
        return new ArrayList<String>(Arrays.asList(values));
    }

    private static final class RecordingPersistence implements ItemListTransaction.Persistence {
        private final List<String> items;
        private final boolean result;
        private List<String> observedItems;
        private int calls;

        RecordingPersistence(List<String> items, boolean result) {
            this.items = items;
            this.result = result;
        }

        @Override
        public boolean persist() {
            calls += 1;
            observedItems = new ArrayList<String>(items);
            return result;
        }
    }

    private static final class ThrowingPersistence implements ItemListTransaction.Persistence {
        private final List<String> items;
        private final RuntimeException error;
        private List<String> observedItems;
        private int calls;

        ThrowingPersistence(List<String> items, RuntimeException error) {
            this.items = items;
            this.error = error;
        }

        @Override
        public boolean persist() {
            calls += 1;
            observedItems = new ArrayList<String>(items);
            throw error;
        }
    }
}
