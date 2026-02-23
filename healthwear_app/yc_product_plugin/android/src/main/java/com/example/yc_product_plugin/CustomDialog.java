package com.example.yc_product_plugin;

import android.content.Context;
import android.view.Gravity;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.wevey.selector.dialog.MDAlertDialog;

import java.lang.reflect.Field;

public class CustomDialog extends MDAlertDialog {
    public CustomDialog(Builder builder) {
        super(builder);
        // TODO: 2023/3/2 修改mRightBtn文本换行bug 代码混淆时需要注意
        try {
            Class<MDAlertDialog> objClass = MDAlertDialog.class;
            Field fieldView = objClass.getDeclaredField("mRightBtn");
            fieldView.setAccessible(true);
            TextView mRightBtn = (TextView) fieldView.get(this);
            if (mRightBtn != null) {
                mRightBtn.setMaxLines(1);
                mRightBtn.setMinWidth(100);
                mRightBtn.setMaxWidth(Integer.MAX_VALUE);
                LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);

                params.gravity = Gravity.CENTER;
                mRightBtn.setLayoutParams(params);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public static class Builder extends MDAlertDialog.Builder {

        public Builder(Context context) {
            super(context);
        }

        @Override
        public MDAlertDialog build() {
            return new CustomDialog(this);
        }
    }

}
