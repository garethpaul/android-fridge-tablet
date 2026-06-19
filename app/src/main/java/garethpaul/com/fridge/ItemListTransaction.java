package garethpaul.com.fridge;

import java.util.ArrayList;
import java.util.List;

final class ItemListTransaction {
    enum Result {
        COMMITTED,
        ROLLED_BACK,
        UNCHANGED
    }

    interface Persistence {
        boolean persist(List<String> proposedItems);
    }

    Result add(List<String> items, String item, Persistence persistence) {
        synchronized (items) {
            ArrayList<String> proposedItems = new ArrayList<String>(items);
            proposedItems.add(item);
            if (persistence.persist(proposedItems)) {
                items.clear();
                items.addAll(proposedItems);
                return Result.COMMITTED;
            }
            return Result.ROLLED_BACK;
        }
    }

    Result remove(List<String> items, int position, Persistence persistence) {
        if (position < 0 || position >= items.size()) {
            return Result.UNCHANGED;
        }

        synchronized (items) {
            if (position < 0 || position >= items.size()) {
                return Result.UNCHANGED;
            }
            ArrayList<String> proposedItems = new ArrayList<String>(items);
            proposedItems.remove(position);
            if (persistence.persist(proposedItems)) {
                items.clear();
                items.addAll(proposedItems);
                return Result.COMMITTED;
            }
            return Result.ROLLED_BACK;
        }
    }
}
