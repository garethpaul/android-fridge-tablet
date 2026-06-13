package garethpaul.com.fridge;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;

import org.apache.commons.io.FileUtils;

public class MainActivity extends Activity {

    private static final String LOG_TAG = "Fridge";
    private static final String DISPLAY_DATE_PATTERN = "M-d-yyyy";
    private static final String ITEM_FILE_ENCODING = "UTF-8";
    private static final String ITEM_TEMP_FILE_NAME = "food.txt.tmp";

    private ArrayList<String> items;
    private ArrayAdapter<String> itemsAdapter;
    private ListView lvItems;
    private TextView dateTime;
    private boolean itemStorageAvailable;

    private String textFileName = "food.txt";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        //Remove notification bar
        this.getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        setContentView(R.layout.activity_main);

        // Add items ListView
        lvItems = (ListView) findViewById(R.id.listView);
        items = new ArrayList<String>();

        // Read existing items from file
        readItems();

        itemsAdapter = new ArrayAdapter<String>(this,
                android.R.layout.simple_list_item_1, items);
        if (lvItems != null) {
            lvItems.setAdapter(itemsAdapter);
        }

        // Remove warnings
        EditText etNewItem = (EditText) findViewById(R.id.editText);
        if (etNewItem != null) {
            etNewItem.requestFocus();
            InputMethodManager inputManager = (InputMethodManager)this.getSystemService(INPUT_METHOD_SERVICE);
            if (inputManager != null) {
                inputManager.restartInput(etNewItem);
            }
        }

        // SetupListView
        setupListViewListener();

        // Setup Time
        setupTime();
    }

    // Displays current date on top bar
    private void setupTime(){

        String date = new SimpleDateFormat(DISPLAY_DATE_PATTERN, Locale.US).format(new Date());

        dateTime = (TextView) findViewById(R.id.dateTime);
        if (dateTime != null) {
            dateTime.setText(date);
        }

    }
    // Attaches a long click listener to the ListView
    private void setupListViewListener() {
        if (lvItems == null) {
            return;
        }

        lvItems.setOnItemLongClickListener(
                new AdapterView.OnItemLongClickListener() {
                    @Override
                    public boolean onItemLongClick(AdapterView<?> adapter,
                                                   View item, int pos, long id) {
                        if (pos < 0 || pos >= items.size()) {
                            return true;
                        }

                        // Remove the item within array at position
                        String removedItem = items.remove(pos);
                        // Refresh the adapter
                        itemsAdapter.notifyDataSetChanged();
                        if (!writeItems()) {
                            items.add(pos, removedItem);
                            itemsAdapter.notifyDataSetChanged();
                            showWriteError();
                        }
                        // Return true consumes the long click event (marks it handled)
                        return true;
                    }

                });
    }

    // Adds item to view
    public void onAddItem(View v) {
        if (!itemStorageAvailable) {
            showReadError();
            return;
        }

        EditText etNewItem = (EditText) findViewById(R.id.editText);
        String itemText = normalizedItemText(etNewItem);
        if (itemText.length() == 0) {
            return;
        }

        // Add the item to the ListView
        int addedPosition = items.size();
        items.add(itemText);
        itemsAdapter.notifyDataSetChanged();

        if (!writeItems()) {
            items.remove(addedPosition);
            itemsAdapter.notifyDataSetChanged();
            showWriteError();
            return;
        }

        // Set the text to empty
        etNewItem.setText("");

        // Hide the keyboard
        InputMethodManager mgr = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
        if (mgr != null) {
            mgr.hideSoftInputFromWindow(etNewItem.getWindowToken(), 0);
        }

    }

    private String normalizedItemText(EditText itemInput) {
        if (itemInput == null || itemInput.getText() == null) {
            return "";
        }

        return itemInput.getText().toString()
                .replace('\r', ' ')
                .replace('\n', ' ')
                .trim();
    }

    // Read Items from persistent storage
    private void readItems() {
        File filesDir = getFilesDir();
        File todoFile = new File(filesDir, textFileName);
        items = new ArrayList<String>();
        try {
            if (!todoFile.exists()) {
                itemStorageAvailable = true;
                return;
            }

            items = new ArrayList<String>(FileUtils.readLines(
                    todoFile,
                    ITEM_FILE_ENCODING));
            itemStorageAvailable = true;
        } catch (IOException | SecurityException e) {
            itemStorageAvailable = false;
            Log.w(LOG_TAG, "Unable to read fridge items");
            showReadError();
        }
    }

    // Write items to persistent storage
    private boolean writeItems() {
        if (!itemStorageAvailable) {
            return false;
        }

        File filesDir = getFilesDir();
        File todoFile = new File(filesDir, textFileName);
        File temporaryFile = new File(filesDir, ITEM_TEMP_FILE_NAME);
        boolean written = false;
        try {
            FileUtils.writeLines(temporaryFile, ITEM_FILE_ENCODING, items);
            if (!temporaryFile.renameTo(todoFile)) {
                throw new IOException("Unable to replace fridge item file");
            }
            written = true;
        } catch (IOException | SecurityException e) {
            Log.w(LOG_TAG, "Unable to write fridge items");
        } finally {
            boolean temporaryFileRemoved;
            try {
                temporaryFileRemoved = !temporaryFile.exists() || temporaryFile.delete();
            } catch (SecurityException e) {
                temporaryFileRemoved = false;
            }
            if (!temporaryFileRemoved) {
                Log.w(LOG_TAG, "Unable to remove temporary fridge item file");
            }
        }
        return written;
    }

    private void showWriteError() {
        Toast.makeText(this, R.string.write_items_error, Toast.LENGTH_SHORT).show();
    }

    private void showReadError() {
        Toast.makeText(this, R.string.read_items_error, Toast.LENGTH_SHORT).show();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        if (menu == null) {
            return false;
        }

        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item == null) {
            return false;
        }

        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }
}
