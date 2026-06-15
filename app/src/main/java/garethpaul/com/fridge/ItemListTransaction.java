package garethpaul.com.fridge;

import java.util.List;

final class ItemListTransaction {
    enum Result {
        COMMITTED,
        ROLLED_BACK,
        UNCHANGED
    }

    interface Persistence {
        boolean persist();
    }

    Result add(List<String> items, String item, Persistence persistence) {
        int addedPosition = items.size();
        items.add(item);
        try {
            if (persistence.persist()) {
                return Result.COMMITTED;
            }
        } catch (RuntimeException error) {
            items.remove(addedPosition);
            throw error;
        }

        items.remove(addedPosition);
        return Result.ROLLED_BACK;
    }

    Result remove(List<String> items, int position, Persistence persistence) {
        if (position < 0 || position >= items.size()) {
            return Result.UNCHANGED;
        }

        String removedItem = items.remove(position);
        try {
            if (persistence.persist()) {
                return Result.COMMITTED;
            }
        } catch (RuntimeException error) {
            items.add(position, removedItem);
            throw error;
        }

        items.add(position, removedItem);
        return Result.ROLLED_BACK;
    }
}
