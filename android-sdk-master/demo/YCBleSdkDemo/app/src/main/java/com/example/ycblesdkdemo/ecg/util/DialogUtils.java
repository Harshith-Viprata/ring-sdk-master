
package com.example.ycblesdkdemo.ecg.util;

import android.app.Dialog;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.example.ycblesdkdemo.R;

public class DialogUtils {

    private static TextView tv_title;

    /**
     * 长时间的Toast提示
     *
     * @param context
     * @param msg
     */
    public static void showToast(Context context, String msg) {

        Toast.makeText(context, msg, Toast.LENGTH_LONG).show();
    }

    /**
     * 长时间的Toast提示
     *
     * @param context
     * @param msgId
     */
    public static void showToast(Context context, int msgId) {

        Toast.makeText(context, msgId, Toast.LENGTH_LONG).show();
    }

    /**
     * 短时间的Toast提示
     *
     * @param context
     * @param msgId
     */
    public static void showToastShort(Context context, int msgId) {

        Toast.makeText(context, msgId, Toast.LENGTH_SHORT).show();
    }

    /**
     * 短时间的Toast提示
     *
     * @param context
     * @param
     */
    public static void showToastShort(Context context, String msg) {

        Toast.makeText(context, msg, Toast.LENGTH_SHORT).show();
    }

    /**
     * 创建自定义ProgressDialog
     *
     * @param context
     * @return
     */
    public static Dialog createLoadingDialog(Context context) {

        LayoutInflater inflater = LayoutInflater.from(context);
        View v = inflater.inflate(R.layout.layout_loading_dialog, null); // 得到加载view
        LinearLayout layout = (LinearLayout) v.findViewById(R.id.dialog_view); // 加载布局
        tv_title = v.findViewById(R.id.tv_title);
        Dialog loadingDialog = new Dialog(context, R.style.loading_dialog); // 创建自定义样式dialog
        loadingDialog.setCancelable(false); // 不可以用"返回键"取消
        loadingDialog.setContentView(layout, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));
        return loadingDialog;
    }

    /**
     * 创建自定义ProgressDialog
     *
     * @param context
     * @return
     */
    public static Dialog createUpgradingDialog(Context context) {

        LayoutInflater inflater = LayoutInflater.from(context);
        View v = inflater.inflate(R.layout.layout_loading_dialog, null); // 得到加载view
        LinearLayout layout = (LinearLayout) v.findViewById(R.id.dialog_view); // 加载布局
        tv_title = v.findViewById(R.id.tv_title);
        tv_title.setText(R.string.updating);
        Dialog loadingDialog = new Dialog(context, R.style.loading_dialog); // 创建自定义样式dialog
        loadingDialog.setCancelable(false); // 不可以用"返回键"取消
        loadingDialog.setContentView(layout, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));
        return loadingDialog;
    }

    public static void setTiltleVisiable(int visiable) {
        if (tv_title != null)
            tv_title.setVisibility(visiable);
    }

    public static void setTiltle(String title) {
        if (title != null && tv_title != null)
            tv_title.setText(title);
    }

    /**
     * 创建自定义ProgressDialog
     *
     * @param context
     * @return
     */
    public static Dialog createProgressDialog(Context context) {
        LayoutInflater inflater = LayoutInflater.from(context);
        View v = inflater.inflate(R.layout.dialog_dial_custom_installing, null); // 得到加载view
        LinearLayout layout = (LinearLayout) v.findViewById(R.id.dialog_view); // 加载布局
        progressBar = v.findViewById(R.id.dial_item_progress);
        tv_progress = v.findViewById(R.id.dial_item_progress_tv);
        Dialog loadingDialog = new Dialog(context, R.style.AlertDialogStyle); // 创建自定义样式dialog
        loadingDialog.setCancelable(false); // 不可以用"返回键"取消
        loadingDialog.setCanceledOnTouchOutside(false);
        loadingDialog.setContentView(layout, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
        return loadingDialog;
    }

    private static TextView tv_progress;
    private static ProgressBar progressBar;

    public static void setProgress(int progress) {
        progressBar.setProgress(progress);
        tv_progress.setText(progress + "%");
    }
}
