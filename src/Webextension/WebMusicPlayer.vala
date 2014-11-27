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

namespace WebMusic.Webextension {

    private abstract class WebMusicPlayer : Player {

        private uint mTimerId = 0;

        private bool mCanNext          = false;
        private bool mCanPrev          = false;
        private bool mCanShuffle       = false;
        private bool mShuffle          = false;
        private bool mLike             = false;

        private PlayStatus mPlayStatus = PlayStatus.STOP;
        private Repeat     mLoopStatus = Repeat.NONE;

        private delegate void CacheFinishedDelegate(string artist, string track,
                                                    string album, string artUrl, string fileName);

        protected abstract string GetArtist();
        protected abstract string GetTrack();
        protected abstract string GetArtUrl();
        protected abstract string GetAlbum();
        protected abstract bool   GetReady();

        private string _Artist { get; set; }
        private string _Track  { get; set; }
        private string _ArtUrl { get; set; }
        private string _Album  { get; set; }

        protected void StartCheckDom() {
            if(mTimerId == 0) {
                mTimerId = Timeout.add_seconds(1, checkDom);
            }
        }

        protected void StopCheckDom() {
            if(mTimerId != 0) {
                Source.remove(mTimerId);
                mTimerId = 0;
            }
        }

        protected void Reset() {
            _Artist = "";
            _Track  = "";
            _ArtUrl = "";
            _Album  = "";

            mCanNext    = false;
            mCanPrev    = false;
            mCanShuffle = false;
            mShuffle    = false;
            mLike       = false;
        }

        private bool checkDom(){
            if(GetReady()) {
                CheckPlayerControls();
                CheckMetaData();
            }
            return true;
        }

        private void CheckMetaData() {

            string artist = this.GetArtist();
            string track  = this.GetTrack();
            string artUrl = this.GetArtUrl();
            string album  = this.GetAlbum();

            if(artist.length == 0 || track.length == 0)
                return;

            if(artist     != this._Artist
                || track  != this._Track
                || artUrl != this._ArtUrl
                || album  != this._Album) {

                string nartUrl = artUrl.replace("https://", "http://");
                this.CacheCover(artist, track, album, nartUrl, SendMetadataChanged);

                this._Artist = artist;
                this._Track  = track;
                this._ArtUrl = artUrl;
                this._Album = album;
            }

        }

        private void CheckPlayerControls() {
            bool canNext          = this.CanGoNext;
            bool canPrev          = this.CanGoPrevious;
            bool canShuffle       = this.CanShuffle;
            bool shuffle          = this.Shuffle;
            bool like             = this.Like;
            PlayStatus playStatus = this.PlaybackStatus;
            Repeat loopStatus     = this.LoopStatus;

            if(this.mCanNext        != canNext
                || this.mCanPrev    != canPrev
                || this.mCanShuffle != canShuffle
                || this.mShuffle    != shuffle
                || this.mLike       != like
                || this.mPlayStatus != playStatus
                || this.mLoopStatus != loopStatus) {

                this.PlayercontrolChanged(canNext, canPrev, canShuffle,
                    false, shuffle, like, playStatus, loopStatus);

                this.mCanNext    = canNext;
                this.mCanPrev    = canPrev;
                this.mCanShuffle = canShuffle;
                this.mShuffle    = shuffle;
                this.mLike       = like;
                this.mPlayStatus = playStatus;
                this.mLoopStatus = loopStatus;
            }
        }

        private void SendMetadataChanged(string artist, string track,
                                        string album, string artUrl, string fileName) {
            string nfileName = "file://" + fileName;
            this.MetadataChanged(artist, track, album, nfileName);
        }

        private void CacheCover(string artist, string track, string album,
                                string artUrl, CacheFinishedDelegate dele) {           

            if(artUrl.length == 0) {
                debug("No art url for %s by %s from %s.".printf(track, artist, album));
                dele(artist, track, album, artUrl, "");
                return;
            }
            
            string fExtension = artUrl.substring(artUrl.last_index_of_char('.'));
            string fArtist    = artist.length > 0 ? artist + "_" : "";
            string fName      = album.length  > 0 ? album : track;

            if(fName.length == 0) {
                //No track or album given. Generate id which is useable only one time
                string date = new DateTime.now_utc().to_string();
                fName = GLib.Checksum.compute_for_string(ChecksumType.MD5, date, date.length);
            }

            string fileName = (fArtist + fName + fExtension).replace(" ", "_").replace("/", "_");
            fileName = Directory.GetAlbumArtDir() + fileName;

            var cachedImage = File.new_for_path(fileName);
            if(!cachedImage.query_exists()) {
                
                var onlineImage = File.new_for_uri(artUrl);
                onlineImage.load_contents_async.begin(null, (obj, res) => {
                    try {
                        uint8[] contents;
                        string etag_out;

                        onlineImage.load_contents_async.end(res, out contents, out etag_out);

                        FileOutputStream os = cachedImage.append_to(FileCreateFlags.NONE);
                        os.write(contents);
                        os.close();

                    } catch (Error e) {
                        warning("Could not load cover. (%s)", e.message);
                        //Error, no Image obtained
                        fileName = "";
                    }
                    dele(artist, track, album, artUrl, fileName);
                });
            }
            else
            {
                //Image already cached, everything OK
                dele(artist, track, album, artUrl, fileName);
            }

        }
    }
}