package com.example.ycblesdkdemo.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import com.example.ycblesdkdemo.R;
import com.example.ycblesdkdemo.model.FileBean;

import java.util.ArrayList;
import java.util.List;

/**
 * @author zengchong
 * @date 2021/1/11
 * @desc one word for this class
 */
public class FileAdapter extends BaseAdapter {
    private List<FileBean> datas;
    private Context context;

    public FileAdapter(Context context, List<FileBean> datas) {
        if (datas == null) {
            datas = new ArrayList<>();
        }
        this.datas = datas;
        this.context = context;
    }

    @Override
    public int getCount() {
        return datas != null ? datas.size() : 0;
    }

    @Override
    public Object getItem(int position) {
        return datas.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        Holder holder;
        if (convertView == null) {
            convertView = LayoutInflater.from(context).inflate(R.layout.item_ui_url, parent, false);
            holder = new Holder();
            holder.iv_head = convertView.findViewById(R.id.item_ui_url_image);
            holder.tv_name = convertView.findViewById(R.id.item_ui_url_name);
            convertView.setTag(holder);
        } else {
            holder = (Holder) convertView.getTag();
        }
        final FileBean data = datas.get(position);
        if (data.type == 1) {
            holder.iv_head.setImageResource(R.mipmap.bin_file);
        } else if (data.type == 2) {
            holder.iv_head.setImageResource(R.mipmap.zip_file);
        } else {
            holder.iv_head.setImageResource(R.mipmap.folder);
        }
        holder.tv_name.setText(data.name);
        return convertView;
    }

    private static class Holder {
        private ImageView iv_head;
        private TextView tv_name;
    }

    public void setDataChanged(List<FileBean> datas) {
        if (datas == null) {
            datas = new ArrayList<>();
        }
        this.datas = datas;
        notifyDataSetChanged();
    }

}