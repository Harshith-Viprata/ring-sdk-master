package com.example.ycblesdkdemo.ecg;

import android.app.Activity;
import android.app.Dialog;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.example.ycblesdkdemo.R;
import com.example.ycblesdkdemo.ecg.util.DialogUtils;
import com.example.ycblesdkdemo.ecg.util.SharedPreferencesUtil;
import com.example.ycblesdkdemo.ecg.view.Cardiograph2View;
import com.example.ycblesdkdemo.view.NavigationBar;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

import androidx.core.app.ActivityCompat;

public class EcgMsgActivity extends Activity {
    private static final String TAG = EcgMsgActivity.class.getSimpleName();
    Cardiograph2View cardiographView;
    List<Integer> blist = new ArrayList<>();
    private Dialog mLoading;
    private static final int LOADING = 1001;
    private static final int SAVE = 1002;
    private String timeStr;

    private TextView xylal;
    private TextView xllal;
    private TextView tv_hrv;

    class HeartMsgHandler extends Handler {
        //弱引用<引用外部类>
        WeakReference<EcgMsgActivity> mActivity;

        HeartMsgHandler(EcgMsgActivity activity) {
            //构造创建弱引用
            mActivity = new WeakReference<>(activity);
        }

        @Override
        public void handleMessage(Message msg) {
            //通过弱引用获取外部类.
            EcgMsgActivity activity = mActivity.get();
            //进行非空再操作
            if (activity != null) {
                switch (msg.what) {
                    case SAVE:
                        loadBitmapFromView(cardiographView);
                        mLoading.dismiss();
                        break;
                    case LOADING:
                        heartMsgHandler.sendEmptyMessage(SAVE);
                        break;
                }
            }
        }
    }

    private HeartMsgHandler heartMsgHandler = new HeartMsgHandler(this);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_heart_msg);
        init();
        initData();
        addView();
    }

    private void init() {
        xylal = findViewById(R.id.xylal);
        xllal = findViewById(R.id.xllal);
        tv_hrv = findViewById(R.id.tv_hrv);
        mLoading = DialogUtils.createLoadingDialog(this);
        DialogUtils.setTiltleVisiable(View.GONE);
        NavigationBar bar = findViewById(R.id.navigationbar);
        // 设置Title
        bar.setTitle(getString(R.string.electrocardiogram));
        bar.showLeftbtn(0);
        bar.setLeftOnClickListener(new NavigationBar.MyOnClickListener() {
            @Override
            public void onClick(View btn) {
                finish();
            }
        });
        bar.setRightImage(R.mipmap.save);
        bar.setRight2OnClickListener(new NavigationBar.MyOnClickListener() {
            @Override
            public void onClick(View btn) {
                //loadBitmapFromView(cardiographView);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    String[] PERMISSIONS_STORAGE = {
                            "android.permission.READ_EXTERNAL_STORAGE",
                            "android.permission.WRITE_EXTERNAL_STORAGE"};
                    //检测是否有写的权限
                    int permission = ActivityCompat.checkSelfPermission(EcgMsgActivity.this,
                            "android.permission.WRITE_EXTERNAL_STORAGE");
                    if (permission != PackageManager.PERMISSION_GRANTED) {
                        // 没有写的权限，去申请写的权限，会弹出对话框
                        ActivityCompat.requestPermissions(EcgMsgActivity.this, PERMISSIONS_STORAGE, 1);
                    } else {
                        mLoading.show();
                        heartMsgHandler.sendEmptyMessage(LOADING);
                    }
                } else {
                    mLoading.show();
                    heartMsgHandler.sendEmptyMessage(LOADING);
                }
            }
        });
    }

    private void initData() {
        if (getIntent() == null)
            return;
        timeStr = getIntent().getStringExtra("timeStr");
        //demo暂时保存在sharepreferences中，建议保存在数据库中  记录界面用来展示
        blist.addAll(SharedPreferencesUtil.readEcgListMsg(timeStr, EcgMsgActivity.this));
        int minBP = getIntent().getIntExtra("minBP", 0);
        int maxBP = getIntent().getIntExtra("maxBP", 0);
        setData(maxBP + "/" + minBP, getIntent().getStringExtra("heart"), getIntent().getStringExtra("hrv"));
    }

    private void setData(String bp, String heart, String hrv) {
        try {
            int minBP = Integer.parseInt(bp.split("/")[1]);
            int maxBP = Integer.parseInt(bp.split("/")[0]);
            if (minBP < 40 || minBP > 160 || maxBP < 70 || maxBP > 250 || (maxBP - minBP) < 10 || (maxBP - minBP) > 80) {
                xylal.setVisibility(View.GONE);
            } else {
                xylal.setText(getString(R.string.blood_pressure) + ":" + bp);
                xylal.setVisibility(View.VISIBLE);
            }
        } catch (Exception e) {
            e.printStackTrace();
            xylal.setVisibility(View.GONE);
        }
        try {
            if (Integer.parseInt(heart) >= 40) {
                xllal.setText(getString(R.string.heart) + ":" + heart);
                xllal.setVisibility(View.VISIBLE);
            } else {
                xllal.setVisibility(View.GONE);
            }
        } catch (Exception e) {
            e.printStackTrace();
            xllal.setVisibility(View.GONE);
        }
        try {
            if (Integer.parseInt(hrv) > 0) {
                if (Integer.parseInt(hrv) > 150) {
                    hrv = "150";
                }
                tv_hrv.setText(getString(R.string.hrv) + ":" + hrv);
                tv_hrv.setVisibility(View.VISIBLE);
            } else {
                tv_hrv.setVisibility(View.GONE);
            }
        } catch (Exception e) {
            e.printStackTrace();
            tv_hrv.setVisibility(View.GONE);
        }
    }

    public void addView() {
        RelativeLayout aaaax = (RelativeLayout) findViewById(R.id.aaaax);

        cardiographView = new Cardiograph2View(this);
        cardiographView.setDatas(blist, false);

        float scale = getResources().getDisplayMetrics().density;
        int ax = (int) (cardiographView.getDatas().size() * scale);

        RelativeLayout.LayoutParams layte = new RelativeLayout.LayoutParams(
                ax,
                RelativeLayout.LayoutParams.MATCH_PARENT
        );

        aaaax.addView(cardiographView, layte);


        cardiographView.make(ax);
        cardiographView.invalidate();
    }


    private void loadBitmapFromView(View v) {
        int w = v.getWidth();
        int h = v.getHeight();
        if (h == 0 || w == 0) {
            Toast.makeText(EcgMsgActivity.this, getString(R.string.save_failed), Toast.LENGTH_SHORT).show();
            return;
        }
        Bitmap bmp = Bitmap.createBitmap(w, h, Bitmap.Config.RGB_565);
        Canvas c = new Canvas(bmp);
        //c.drawColor(Color.WHITE);
        // 如果不设置canvas画布为白色，则生成透明
        v.layout(0, 0, w, h);
        v.draw(c);
        saveBitmap(bmp, timeStr + ".png");
        if (!bmp.isRecycled()) {
            bmp.recycle();
            Log.i(TAG, " recycle。。。。。。。。。。");
        }
        //Tools.showAlert3(_context, getString(R.string.save_success));
    }

//    private Bitmap small(Bitmap bitmap) {
//        Matrix matrix = new Matrix();
//        matrix.postScale(0.5f, 0.5f); //长和宽放大缩小的比例
//        bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
//        //   Log.i(TAG, "small: w:" + bitmap.getWidth() + " h: " + bitmap.getHeight() + " wh=" + bitmap.getHeight() * bitmap.getWidth());
//        return bitmap;
//    }

    private void saveBitmap(Bitmap bitmap, String bitName) {
        /*if (Build.VERSION.SDK_INT > Build.VERSION_CODES.Q) {
            if (SystemUiUtil.saveImageToGallery(EcgMsgActivity.this, bitmap, bitName)) {
                Tools.showAlert3(_context, getString(R.string.save_success));
            } else {
                Tools.showAlert3(_context, getString(R.string.save_failed));
            }
        } else {
            File file = new File(SystemUiUtil.isExistDir("/health/ecg"), bitName);
            FileOutputStream out = null;
            try {
                out = new FileOutputStream(file);
                if (bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)) {
                    out.flush();
                    Tools.showAlert3(_context, getString(R.string.save_success));
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {//如果是4.4及以上版本
                        Intent mediaScanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
                        Uri contentUri = Uri.fromFile(file); //out is your output file
                        mediaScanIntent.setData(contentUri);
                        sendBroadcast(mediaScanIntent);
                    } else {
                        sendBroadcast(new Intent(Intent.ACTION_MEDIA_MOUNTED, Uri.parse("file://" + Environment.getExternalStorageDirectory())));
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                Tools.showAlert3(_context, getString(R.string.save_failed));
            } finally {
                try {
                    if (out != null) {
                        out.close();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }*/
    }
}
