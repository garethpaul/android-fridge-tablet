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
                .replace('\n', ' ');
        value = trimUnicodeSpace(value);
        return isValidItem(value) ? value : null;
    }

    private static String trimUnicodeSpace(String value) {
        int start = 0;
        int end = value.length();
        while (start < end) {
            int codePoint = value.codePointAt(start);
            if (!Character.isWhitespace(codePoint) && !Character.isSpaceChar(codePoint)) {
                break;
            }
            start += Character.charCount(codePoint);
        }
        while (end > start) {
            int codePoint = value.codePointBefore(end);
            if (!Character.isWhitespace(codePoint) && !Character.isSpaceChar(codePoint)) {
                break;
            }
            end -= Character.charCount(codePoint);
        }
        return value.substring(start, end);
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
        boolean hasVisibleContent = false;
        for (int offset = 0; offset < item.length();) {
            int codePoint = item.codePointAt(offset);
            if (isProhibitedCodePoint(codePoint)) {
                return false;
            }
            if (!isInvisibleCodePoint(codePoint) && !isCombiningMark(codePoint)) {
                hasVisibleContent = true;
            }
            offset += Character.charCount(codePoint);
        }
        if (!hasVisibleContent) {
            return false;
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

    private static boolean isInvisibleCodePoint(int codePoint) {
        return Character.isWhitespace(codePoint)
                || Character.isSpaceChar(codePoint)
                || Character.getType(codePoint) == Character.FORMAT
                || isDefaultIgnorableCombiningMark(codePoint);
    }

    private static boolean isDefaultIgnorableCombiningMark(int codePoint) {
        return codePoint == 0x034F
                || (codePoint >= 0x180B && codePoint <= 0x180D)
                || codePoint == 0x180F
                || (codePoint >= 0xFE00 && codePoint <= 0xFE0F)
                || (codePoint >= 0xE0100 && codePoint <= 0xE01EF);
    }

    private static boolean isCombiningMark(int codePoint) {
        int type = Character.getType(codePoint);
        return type == Character.NON_SPACING_MARK
                || type == Character.COMBINING_SPACING_MARK
                || type == Character.ENCLOSING_MARK;
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
