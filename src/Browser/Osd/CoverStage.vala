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

    public class CoverStage : GtkClutter.Embed {
    
        private Clutter.Stage    mStage;
        private Clutter.Actor    mCoverActor;
        private Clutter.Image    mImage;
        private ControlsActor    mControlsActor;
        
        public void Init(IPlayer player, Service service) {
        
            mImage = new Clutter.Image();        
            mCoverActor = new Clutter.Actor();

            mControlsActor = new ControlsActor(player, service);
            mControlsActor.x_expand = true;
            mControlsActor.y_expand = true;
            mControlsActor.x_align = Clutter.ActorAlign.END;
            mControlsActor.y_align = Clutter.ActorAlign.CENTER;
            mControlsActor.margin_bottom = 10.0f;
            mControlsActor.margin_left   = 10.0f;
            mControlsActor.margin_right  = 10.0f;
            mControlsActor.margin_top    = 10.0f;
            mControlsActor.enter_event.connect((event) => {
                this.ShowControls(true);
                return false;
            });
            
            mStage = (Clutter.Stage) this.get_stage();
            mStage.background_color = Clutter.Color.from_string("white");
            mStage.layout_manager = new Clutter.BinLayout();
            mStage.add_child(mCoverActor);
            mStage.add_child(mControlsActor);
            
            this.enter_notify_event.connect((event) => {
                this.ShowControls(true);
                return false;
            });
            
            this.leave_notify_event.connect((event) => {
                this.ShowControls(false);
                return false;
            });
        }
        
        public void ShowControls(bool show) {
            if(mControlsActor != null) {
                mControlsActor.BlendIn(show);
            }        
        }
        
        public void LoadStockIcon(string name) {
            try {
                Gtk.IconTheme theme = Gtk.IconTheme.get_default();
                Gdk.Pixbuf? pixbuf = theme.load_icon_for_scale(name, 128, 1, Gtk.IconLookupFlags.FORCE_SIZE);
                
                if(pixbuf == null) {
                    critical("No icon named %s found in icon theme.", name);
                } else {
                    SetPixbuf(pixbuf);
                }
            } catch(Error e) {
                critical("Could not load stock icon %s. (%s)", name, e.message);
            }
        }
        
        public void LoadImage(string coverPath) {
            try {
                Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(coverPath);
                SetPixbuf(pixbuf);
            } catch(Error e) {
                critical("Could not load pixbuf from path %s. (%s)", coverPath, e.message);
            }
        }
        
        private void SetPixbuf(Gdk.Pixbuf pixbuf) throws Error {

                mImage.set_data(pixbuf.get_pixels(),
                    pixbuf.has_alpha ? Cogl.PixelFormat.RGBA_8888 : Cogl.PixelFormat.RGB_888,
                    pixbuf.width, pixbuf.height, pixbuf.rowstride);

                mCoverActor.content = mImage;
                mCoverActor.set_size(pixbuf.width, pixbuf.height);
                
                this.set_size_request((int)mCoverActor.width + 10, (int)mCoverActor.height + 10);
                mCoverActor.set_position(5, 5);
        }
    
    }

}
