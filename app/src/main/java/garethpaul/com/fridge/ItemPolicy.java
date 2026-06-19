package garethpaul.com.fridge;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetEncoder;
import java.nio.charset.CodingErrorAction;
import java.util.List;

final class ItemPolicy {
    static final long MAX_FILE_BYTES = 1024L * 1024L;
    static final int MAX_ITEM_BYTES = 4096;
    static final int MAX_ITEMS = 512;

    private static final Charset UTF_8 = Charset.forName("UTF-8");

    private ItemPolicy() {
    }

    static String normalizeInput(CharSequence input) {
        if (input == null) {
            return "";
        }

        String value = input.toString()
                .replace('\r', ' ')
                .replace('\n', ' ')
                .trim();
        return isValidItem(value) ? value : null;
    }

    static void validateItems(List<String> items) throws IOException {
        if (items == null || items.size() > MAX_ITEMS) {
            throw new IOException("Invalid fridge item count");
        }

        long encodedBytes = 0;
        for (String item : items) {
            if (!isValidItem(item)) {
                throw new IOException("Invalid fridge item");
            }
            int itemBytes = encodedLength(item);
            if (itemBytes > MAX_ITEM_BYTES || itemBytes > MAX_FILE_BYTES - encodedBytes) {
                throw new IOException("Fridge item storage limit exceeded");
            }
            encodedBytes += itemBytes;
            if (encodedBytes == MAX_FILE_BYTES) {
                throw new IOException("Fridge item storage limit exceeded");
            }
            encodedBytes += 1;
        }
    }

    static boolean isValidItem(String item) {
        if (item == null || item.length() == 0) {
            return false;
        }
        for (int offset = 0; offset < item.length();) {
            int codePoint = item.codePointAt(offset);
            if (isProhibitedCodePoint(codePoint)) {
                return false;
            }
            offset += Character.charCount(codePoint);
        }
        try {
            return encodedLength(item) <= MAX_ITEM_BYTES;
        } catch (IOException error) {
            return false;
        }
    }

    private static boolean isProhibitedCodePoint(int codePoint) {
        return Character.isISOControl(codePoint)
                || codePoint == 0x061C
                || codePoint == 0x200E
                || codePoint == 0x200F
                || (codePoint >= 0x202A && codePoint <= 0x202E)
                || (codePoint >= 0x2066 && codePoint <= 0x2069);
    }

    private static int encodedLength(String value) throws IOException {
        CharsetEncoder encoder = UTF_8.newEncoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT);
        try {
            ByteBuffer encoded = encoder.encode(CharBuffer.wrap(value));
            return encoded.remaining();
        } catch (CharacterCodingException error) {
            throw new IOException("Invalid UTF-8 item", error);
        }
    }
}
