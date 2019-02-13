/*
 * Apache 2.0 License
 *
 * Copyright (c) Hao Lin 2019
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

var exec    = require('cordova/exec'),
    channel = require('cordova/channel');

exports._createCallbackFn = function (fn, scope) {

    if (typeof fn != 'function')
        return;

    return function () {
        fn.apply(scope || this, arguments);
    };
};

exports._exec = function (action, args, callback, scope) {
    var fn     = this._createCallbackFn(callback, scope),
        params = [];

    if (Array.isArray(args)) {
        params = args;
    } else if (args) {
        params.push(args);
    }

    exec(fn, null, 'IjkPlayerMgr', action, params);
};

exports.test = function (callback, scope) {
    //exports._exec('deviceready');
    exports._exec('playerVideo', 'rtmp://119.23.79.45:1935/live/B012');
};

exports.playVideo = function (callback, scope) {
    exports._exec('playerVideo', 'rtmp://119.23.79.45:1935/live/B012');
};


// Called after 'deviceready' event
channel.deviceready.subscribe(function () {
    //exports._exec('deviceready');
});

// Called before 'deviceready' event
channel.onCordovaReady.subscribe(function () {

});
