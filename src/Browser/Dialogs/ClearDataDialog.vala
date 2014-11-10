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

namespace WebMusic.Browser.Dialogs {

    [Flags]
    private enum DataToClear {
        CLEAR_COOKIES,
        CLEAR_ALBUM_ART,
        CLEAR_INTERNET_FILES
    }

    [GtkTemplate (ui = "/org/WebMusic/Browser/ui/clear-data-dialog.ui")]
    private class ClearDataDialog : Gtk.Dialog {
    
        public signal void ClearData(DataToClear dataflags);
    
        [GtkChild]
        private Gtk.Button mBtnClearData;
        
        [GtkChild]
        private Gtk.CheckButton mChkCookies;
        
        [GtkChild]
        private Gtk.CheckButton mChkAlbumArt;
        
        [GtkChild]
        private Gtk.CheckButton mChkTemporaryFiles;
        
        private int mNumChkBtnActive;
        
        public ClearDataDialog() {
            Object (use_header_bar: 1);
            
            this.response.connect(OnResponse);
        }
        
        [GtkCallback]
        private void OnChkBtn(Gtk.Button button) {
            if(((Gtk.ToggleButton)button).active) {
                mNumChkBtnActive++;
            } else {
                mNumChkBtnActive--;
            }
            
            mBtnClearData.sensitive = mNumChkBtnActive > 0;
            
        }
        
        private void OnResponse(int response) {
    
            if(response == Gtk.ResponseType.OK) {
            
                DataToClear data = 0;
                
                if(mChkCookies.active) {
                    data |= DataToClear.CLEAR_COOKIES;
                }
                
                if(mChkAlbumArt.active) {
                    data |= DataToClear.CLEAR_ALBUM_ART;
                }
                
                if(mChkTemporaryFiles.active) {
                    data |= DataToClear.CLEAR_INTERNET_FILES;
                }
                
                if(data != 0) {
                    this.ClearData(data);
                }
            
            }
        
            this.destroy();
        }
    
    }
}
