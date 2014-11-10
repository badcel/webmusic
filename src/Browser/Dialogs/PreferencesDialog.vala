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

    [GtkTemplate (ui = "/org/WebMusic/Browser/ui/preferences-dialog.ui")]
    private class PreferencesDialog : Gtk.Dialog {

        public signal void ClearData(DataToClear dataflags);

        [GtkChild]
        private Gtk.CheckButton mChkNotification;
        
        [GtkChild]
        private Gtk.CheckButton mChkMpris;
        
        [GtkChild]
        private Gtk.ComboBox mCmbDarkTheme;
        
        private Settings mSettingsBrowser;
        private Settings mSettingsWebextension;

        public PreferencesDialog() {
        
            Object (use_header_bar: 1);
        
            mSettingsBrowser = new Settings("org.WebMusic.Browser");
            mSettingsWebextension = new Settings("org.WebMusic.Webextension");
            
            if(mSettingsWebextension == null || mSettingsBrowser == null)
                return;
            
            mSettingsWebextension.bind("enable-mpris", mChkMpris,
                                        "active", SettingsBindFlags.NO_SENSITIVITY);
            mSettingsWebextension.bind("enable-notifications", mChkNotification,
                                        "active", SettingsBindFlags.NO_SENSITIVITY);
            
            mSettingsBrowser.bind_with_mapping("use-dark-theme", mCmbDarkTheme,
                "active", SettingsBindFlags.NO_SENSITIVITY,
            	(value, variant, user_data) => {
        	        Gtk.TreeIter iter;
        	        int i = 0;
        	        
                    var model   = (Gtk.TreeModel)((Gtk.ComboBox)user_data).get_model();
                    var valid   = model.get_iter_first(out iter);
                    var setting = variant.get_string();
                    
                    while(valid) {
                        string item;
                        model.get(iter, 0, out item, -1);
                        
                        if(item == setting) {
                            value.set_int(i);
                            break;
                        }
                        
                        i++;
                        valid = model.iter_next(ref iter);
                        
                    }
                    
                    return true;
                },
                (value, expected_type, user_data) => {
                    Variant v = null;
                    Gtk.TreeIter iter;
                    
                    var n     = value.get_int();
                    var model = (Gtk.TreeModel)((Gtk.ComboBox)user_data).get_model();
                    var valid = model.iter_nth_child(out iter, null, n);
                    
                    if(valid) {
                        string item;
                        model.get(iter, 0, out item, -1);
                        v = new Variant.string(item);
                    }
                    
                    return v;
                },
                mCmbDarkTheme, null);
                
            this.response.connect((response) => {
                this.destroy();
            });
        }
        
        [GtkCallback]
        private void OnBtnClearTemporaryFiles(Gtk.Button button) {
	        var clearData = new ClearDataDialog();
	        clearData.ClearData.connect((data) => {
	            this.ClearData(data);
	        });
	        clearData.set_transient_for(this);
	        clearData.present();
        }

    }

}
