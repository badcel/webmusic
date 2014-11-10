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

using WebMusic.Lib;

namespace WebMusic.Browser.Osd {

    public class ControlsActor : GtkClutter.Actor {        
        
        private CoverToolbar mCoverToolbar;
        private const uint8 OPACITY = 220;

        public ControlsActor(IPlayer player, Service service) {
            
            mCoverToolbar = new CoverToolbar(player, service);
            Gdk.RGBA trans = {0, 0, 0, 0};
            this.get_widget().override_background_color(Gtk.StateFlags.NORMAL, trans);
            
            @set("contents", mCoverToolbar, "opacity", OPACITY);
        }
        
        public void BlendIn(bool blend) {
            
            this.save_easing_state();
            this.set_easing_duration(500);
            uint8 opacity = blend? OPACITY : 0;
            this.set_opacity(opacity);
            this.restore_easing_state();
        
        }
        
        [GtkTemplate (ui = "/org/WebMusic/Browser/ui/osd.ui")]
        private class CoverToolbar : Gtk.Toolbar {

            private IPlayer mPlayer;
            private Service mService;

            [GtkChild]
            private Gtk.ToggleToolButton mBtnShuffle;

            [GtkChild]
            private Gtk.ToggleToolButton mBtnRepeat;
            
            [GtkChild]
            private Gtk.ToggleToolButton mBtnLike;

            public CoverToolbar(IPlayer player, Service service) {
                mPlayer = player;
                mService = service;

                var context = this.get_style_context();
                context.add_class(Gtk.STYLE_CLASS_INLINE_TOOLBAR);
                
                mService.ServiceLoaded.connect(() => {
                    this.InitButtons();
                });

                this.get_style_context().add_class("osd");

                this.InitButtons();

                mPlayer.PlayercontrolChanged.connect(OnPlayercontrolChanged);
            }

            private void InitButtons() {
            
                mBtnShuffle.active = mPlayer.Shuffle;
                mBtnShuffle.visible = mService.SupportsShuffle;

                mBtnRepeat.visible = mService.SupportsLoopStatus;
                
                mBtnLike.active = mPlayer.Like;
                mBtnLike.visible = mService.SupportsLike;
                mBtnLike.sensitive = true; //Like button is always available

                if(!mService.SupportsLoopStatus 
                    && !mService.SupportsShuffle 
                    && !mService.SupportsLike) {
                    this.visible = false;
                } else {
                    this.visible = true;
                }
            }

            [GtkCallback]
            private void OnBtnShuffleToggled() {
                mPlayer.Shuffle = mBtnShuffle.active;
            }
            
            [GtkCallback]
            private void OnBtnLikeToggled() {
                mPlayer.Like = mBtnLike.active;
            }

            [GtkCallback]
            private void OnBtnRepeatToggled() {
                //TODO
                stdout.printf("REPEAT\n");
            }

            private void OnPlayercontrolChanged(bool canGoNext, bool canGoPrev, bool canShuffle,
                        bool canRepeat, bool shuffle, bool like, PlayStatus playStatus, Repeat loopStatus) {

                mBtnShuffle.sensitive = canShuffle;
                mBtnShuffle.active = shuffle;
                                
                mBtnRepeat.sensitive = canRepeat;

                mBtnLike.active = like;
                                            
            }
        }
    
    }

}
