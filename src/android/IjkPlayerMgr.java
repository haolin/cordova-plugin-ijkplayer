/*
 * Apache 2.0 License
 *
 * Copyright (c) Sebastian Katzer 2017
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apache License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://opensource.org/licenses/Apache-2.0/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 */

// codebeat:disable[TOO_MANY_FUNCTIONS]

package org.apache.cordova.ijkplayer;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.util.Pair;
import android.view.View;
import android.content.Intent;
import android.widget.FrameLayout;
import android.view.LayoutInflater;
import android.widget.RelativeLayout;
import android.net.Uri;
import com.galaxy.client.R;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import java.lang.String;

import org.apache.cordova.ijkplayer.media.IjkVideoView;
import org.apache.cordova.ijkplayer.media.IRenderView;

import tv.danmaku.ijk.media.player.IjkMediaPlayer;

public class IjkPlayerMgr extends CordovaPlugin {

    // Reference to the web view for static access
    private static WeakReference<CordovaWebView> webView = null;

    private IjkVideoView mVideoView = null;

    private View mVideoLayout = null;

    /**
     * Called after plugin construction and fields have been initialized.
     * Prefer to use pluginInitialize instead since there is no value in
     * having parameters on the initialize() function.
     */
    @Override
    public void initialize (CordovaInterface cordova, CordovaWebView webView) {
        IjkPlayerMgr.webView = new WeakReference<CordovaWebView>(webView);
    }

    /**
     * Called when the system is about to start resuming a previous activity.
     *
     * @param multitasking		Flag indicating if multitasking is turned on for app
     */
    public void onPause(boolean multitasking) {
    }

    /**
     * Called when the activity will start interacting with the user.
     *
     * @param multitasking Flag indicating if multitasking is turned on for app.
     */
    @Override
    public void onResume (boolean multitasking) {
    }

    /**
     * Called when the activity is becoming visible to the user.
     */
    public void onStart() {
    }

    /**
     * Called when the activity is no longer visible to the user.
     */
    public void onStop() {
    }

    /**
     * Called when the activity receives a new intent.
     */
    public void onNewIntent(Intent intent) {
    }

    /**
     * The final call you receive before your activity is destroyed.
     */
    public void onDestroy() {
    }

    /**
     * Executes the request.
     *
     * This method is called from the WebView thread. To do a non-trivial
     * amount of work, use:
     *      cordova.getThreadPool().execute(runnable);
     *
     * To run on the UI thread, use:
     *     cordova.getActivity().runOnUiThread(runnable);
     *
     * @param action  The action to execute.
     * @param args    The exec() arguments in JSON form.
     * @param command The callback context used when calling back into
     *                JavaScript.
     *
     * @return Whether the action was valid.
     */
    @Override
    public boolean execute (final String action, final JSONArray args,
                            final CallbackContext command) throws JSONException {
        if ("playVideo".equals(action)) {
            if(args.length() == 0){
                return false;
            }
            final String videoUrl = args.getString(0);
            cordova.getActivity().runOnUiThread(new Runnable() {
                public void run() {
                    playVideo(videoUrl, command);
                    //command.success(); // Thread-safe.
                }
            });
            return true;
        }else if ("removeVideo".equals(action)) {
            cordova.getActivity().runOnUiThread(new Runnable() {
                public void run() {
                    removeVideo();
                    command.success(); // Thread-safe.
                }
            });
            return true;
        }
        else if ("disconnectVideo".equals(action)) {
            cordova.getActivity().runOnUiThread(new Runnable() {
                public void run() {
                    disconnectVideo();
                    command.success(); // Thread-safe.
                }
            });
            return true;
        }
        return false;
    }

    private void playVideo(String videoUrl, final CallbackContext command) {
        Activity activity = cordova.getActivity();
        if(mVideoLayout == null){
            RelativeLayout rootView = new RelativeLayout(activity);
            FrameLayout framelayout = (FrameLayout) activity.findViewById(android.R.id.content);
            mVideoLayout = LayoutInflater.from(activity).inflate(R.layout.activity_player, rootView);
            framelayout.addView(mVideoLayout, 0);
        }

        IjkMediaPlayer.loadLibrariesOnce(null);
        IjkMediaPlayer.native_profileBegin("libijkplayer.so");
        mVideoView = (IjkVideoView) activity.findViewById(R.id.video_view);
        mVideoView.setAspectRatio(IRenderView.AR_MATCH_PARENT);
        mVideoView.setVideoPath(videoUrl);
        mVideoView.setCallbackContext(command);
        mVideoView.start();
    }

    private void removeVideo() {
        Activity activity = cordova.getActivity();
        FrameLayout framelayout = (FrameLayout) activity.findViewById(android.R.id.content);
        //View oldView = framelayout.findViewById(R.id.drawer_layout);
        if(mVideoLayout != null){
            IjkVideoView videoView = (IjkVideoView) mVideoLayout.findViewById(R.id.video_view);
            videoView.stopPlayback();
            videoView.release(true);
            videoView.stopBackgroundPlay();
            videoView.removeCallbackContext();
            //videoView.setRender(IjkVideoView.RENDER_NONE);
            IjkMediaPlayer.native_profileEnd();
            framelayout.removeView(mVideoLayout);
            mVideoView = null;
            mVideoLayout = null;
        }
    }

    private void disconnectVideo() {
        Activity activity = cordova.getActivity();
        FrameLayout framelayout = (FrameLayout) activity.findViewById(android.R.id.content);
        //View oldView = framelayout.findViewById(R.id.drawer_layout);
        if(mVideoLayout != null){
            IjkVideoView videoView = (IjkVideoView) mVideoLayout.findViewById(R.id.video_view);
            videoView.stopPlayback();
            videoView.release(true);
            videoView.stopBackgroundPlay();
            videoView.removeCallbackContext();
            //videoView.setRender(IjkVideoView.RENDER_NONE);
            IjkMediaPlayer.native_profileEnd();
            framelayout.removeView(mVideoLayout);
            mVideoView = null;
        }
    }
}

// codebeat:enable[TOO_MANY_FUNCTIONS]
