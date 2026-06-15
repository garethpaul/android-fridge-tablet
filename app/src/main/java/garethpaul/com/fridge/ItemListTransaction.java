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
        if (persistence.persist()) {
            return Result.COMMITTED;
        }

        items.remove(addedPosition);
        return Result.ROLLED_BACK;
    }

    Result remove(List<String> items, int position, Persistence persistence) {
        if (position < 0 || position >= items.size()) {
            return Result.UNCHANGED;
        }

        String removedItem = items.remove(position);
        if (persistence.persist()) {
            return Result.COMMITTED;
        }

        items.add(position, removedItem);
        return Result.ROLLED_BACK;
    }
}
