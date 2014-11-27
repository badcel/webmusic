/*
 *   Copyright (C) 2014  Marcel Tiede
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace WebMusic.Lib {

    public enum PlayStatus {
        STOP,   // INT = 0
        PLAY,   // INT = 1
        PAUSE;  // INT = 2

        public string to_string() {
            string ret = "";

            switch(this) {
                case PlayStatus.STOP:
                    ret = "Stopped";
                    break;
                case PlayStatus.PLAY:
                    ret = "Playing";
                    break;
                case PlayStatus.PAUSE:
                    ret = "Paused";
                    break;
            }

            return ret;
        }
    }

    public enum Repeat {
        NONE,     // INT = 0
        PLAYLIST, // INT = 1
        TRACK;    // INT = 2

        public string to_string() {
            string ret = "";

            switch(this) {
                case Repeat.NONE:
                    ret = "None";
                    break;
                case Repeat.TRACK:
                    ret = "Track";
                    break;
                case Repeat.PLAYLIST:
                    ret = "Playlist";
                    break;
            }

            return ret;
        }
    }

    [DBus(name = "org.WebMusic.Webextension.Player")]
    public interface IPlayer : GLib.Object {

        public signal void MetadataChanged(string artist, string track, string album, string artUrl);
        public signal void PlayercontrolChanged(bool canGoNext, bool canGoPrev, bool canShuffle,
                                                bool canRepeat, bool shuffle, bool like,
                                                PlayStatus playStatus, Repeat loopStatus);

        public abstract bool   Shuffle        { get; set; }
        public abstract bool   Like           { get; set; }
        public abstract Repeat LoopStatus     { get; set; }

        public abstract void Next()     throws IOError;
        public abstract void Previous() throws IOError;
        public abstract void Pause()    throws IOError;
        public abstract void Stop()     throws IOError;
        public abstract void Play()     throws IOError;

        public abstract void PlayPause() throws IOError;
    }
}