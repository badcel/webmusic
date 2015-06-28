/*
 *   Copyright (C) 2015  Marcel Tiede
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

using WebMusic.Lib;

namespace WebMusic.Browser.Widgets.Ui {

    public class RepeatButton : Gtk.Button {

        private static int NUM_STATES = 3;

        private int mCurState = 0;

        construct {
            this.clicked.connect(this.OnClicked);
        }

        public RepeatStatus RepeatState {
            get { return (RepeatStatus) this.mCurState; }
            set {
                this.UpdateState(value);
                this.mCurState = (int) value;
            }
        }

        private void OnClicked() {
            int newState = ++this.mCurState;

            if(newState >= NUM_STATES) {
                newState = 0;
            }
            RepeatStatus rState = (RepeatStatus) newState;
            this.UpdateState(rState);

            this.RepeatState = rState;
        }

        private void UpdateState(RepeatStatus state) {
            switch(state) {
                case RepeatStatus.PLAYLIST:
                    this.set_state_flags(Gtk.StateFlags.CHECKED, false);
                    this.set_label("");
                    break;
                case RepeatStatus.TRACK:
                    this.set_state_flags(Gtk.StateFlags.CHECKED, false);
                    this.set_label("1");
                    break;
                default:
                    //No repeat
                    this.unset_state_flags(Gtk.StateFlags.CHECKED);
                    this.set_label("");
                    break;
            }
        }
    }

}
