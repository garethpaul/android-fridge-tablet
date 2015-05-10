package garethpaul.com.fridge;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.text.format.DateFormat;
import android.text.format.Time;
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

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Timer;
import java.util.TimerTask;

import org.apache.commons.io.FileUtils;

public class MainActivity extends Activity {

    private ArrayList<String> items;
    private ArrayAdapter<String> itemsAdapter;
    private ListView lvItems;
    private TextView dateTime;

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
        lvItems.setAdapter(itemsAdapter);

        // Remove warnings
        EditText etNewItem = (EditText) findViewById(R.id.editText);
        etNewItem.requestFocus();
        InputMethodManager inputManager = (InputMethodManager)this.getSystemService(INPUT_METHOD_SERVICE);
        inputManager.restartInput(etNewItem);

        // SetupListView
        setupListViewListener();

        // Setup Time
        setupTime();
    }

    // Displays current date on top bar
    private void setupTime(){

        Time today = new Time(Time.getCurrentTimezone());
        today.setToNow();
        String date = today.month + "-";
        date += today.monthDay + "-";
        date += today.year;

        dateTime = (TextView) findViewById(R.id.dateTime);
        dateTime.setText(date);

    }
    // Attaches a long click listener to the ListView
    private void setupListViewListener() {
        lvItems.setOnItemLongClickListener(
                new AdapterView.OnItemLongClickListener() {
                    @Override
                    public boolean onItemLongClick(AdapterView<?> adapter,
                                                   View item, int pos, long id) {
                        // Remove the item within array at position
                        items.remove(pos);
                        // Refresh the adapter
                        itemsAdapter.notifyDataSetChanged();
                        //
                        writeItems();
                        // Return true consumes the long click event (marks it handled)
                        return true;
                    }

                });
    }

    // Adds item to view
    public void onAddItem(View v) {
        EditText etNewItem = (EditText) findViewById(R.id.editText);
        String itemText = etNewItem.getText().toString();

        // Add the item to the ListView
        itemsAdapter.add(itemText);

        // Set the text to empty
        etNewItem.setText("");

        // Write items to persistent storage
        writeItems();

        // Hide the keyboard
        InputMethodManager mgr = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
        mgr.hideSoftInputFromWindow(etNewItem.getWindowToken(), 0);

    }

    // Read Items from persistent storage
    private void readItems() {
        Log.v("readItems", "read");
        File filesDir = getFilesDir();
        File todoFile = new File(filesDir, textFileName);
        try {
            items = new ArrayList<String>(FileUtils.readLines(todoFile));
            Log.v("items", items.toString());
        } catch (IOException e) {
            items = new ArrayList<String>();
        }
    }

    // Write items to persistent storage
    private void writeItems() {
        File filesDir = getFilesDir();
        File todoFile = new File(filesDir, textFileName);
        try {
            FileUtils.writeLines(todoFile, items);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
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
