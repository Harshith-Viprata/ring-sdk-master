package com.example.ycblesdkdemo.upgrade;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.view.KeyEvent;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;

import com.example.ycblesdkdemo.R;
import com.example.ycblesdkdemo.adapter.FileAdapter;
import com.example.ycblesdkdemo.model.FileBean;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import androidx.annotation.Nullable;

/**
 * @author StevenLiu
 * @date 2022/5/16
 * @desc one word for this class
 */
public class GetUrlActivity extends Activity {
    private ListView listView;
    private FileAdapter adapter;
    private String sdcardDir;
    private static String currPath;
    private List<FileBean> datas;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_get_url);
        init();
        initData();
    }

    private void init() {
        listView = findViewById(R.id.listview);
    }

    private void initData() {
        try {
            //sd卡的路径
            sdcardDir = Environment.getExternalStorageDirectory().getCanonicalPath();
        } catch (IOException e) {
            e.printStackTrace();
        }
        if (sdcardDir != null) {
            datas = getFileName(sdcardDir);
        }
        adapter = new FileAdapter(GetUrlActivity.this, datas);
        listView.setAdapter(adapter);
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                if (datas.get(position).type == 0) {
                    datas = getFileName(datas.get(position).filePath);
                    adapter.setDataChanged(datas);
                } else if (datas.get(position).type == 1) {
                    setResult(4535, new Intent().putExtra("url", datas.get(position).filePath));
                    finish();
                }
            }
        });
    }

    public static List<FileBean> getFileName(String fileAbsolutePath) {
        currPath = fileAbsolutePath;
        List<FileBean> lists = new ArrayList<>();
        try {
            File[] subFile = new File(fileAbsolutePath).listFiles();
            if (subFile != null && subFile.length > 0) {
                for (File file : subFile) {
                    String fileName = file.getName();
                    System.out.println("chong--------fileName==" + fileName);
                    FileBean bean = new FileBean();
                    if (file.isDirectory()) {//文件夹
                        bean.type = 0;
                    } else if ((fileName.endsWith(".bin") || fileName.endsWith(".zip")) && (fileName.contains("UI") || fileName.contains("DFU"))) {//bin文件
                        bean.type = 1;
                    } else {
                        continue;
                    }
                    bean.name = file.getName();
                    bean.filePath = file.getAbsolutePath();
                    lists.add(bean);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return lists;
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            if (sdcardDir != null && currPath != null && !sdcardDir.equals(currPath)) {
                datas = getFileName(new File(currPath).getParentFile().getAbsolutePath());
                adapter.setDataChanged(datas);
                return true;
            }
        }
        return super.onKeyDown(keyCode, event);
    }
}
