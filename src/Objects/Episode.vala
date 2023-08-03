/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public errordomain EpisodeConstructionError {
        ROW_PARSING_ERROR;
    }

    public class Episode : GLib.Object {

        public string guid { get; construct; }
        public string link { get; construct; }
        public string title { get; construct; }
        public string description { get; construct; }
        public string uri { get; construct set; }
        public string local_uri { get; construct set; }
        public string podcast_uri { get; construct set; }
        public int64 last_played_position { get; construct set; }
        public Podcast parent { get; construct set; }
        public DateTime datetime_released { get; construct; }

        public EpisodeStatus status { get; construct set; default = EpisodeStatus.UNPLAYED; }
        public DownloadStatus current_download_status { get; construct set; default = DownloadStatus.NOT_DOWNLOADED; }

        public signal void download_status_changed ();

        /*
         * Gets the playback uri based on whether the file is local or remote
         * Sets the playback uri based on whether it's local or remote
         */
        public string playback_uri {
            get {
                GLib.File local;

                if (local_uri != null) {
                    if (local_uri.contains ("file://")) {
                        local = GLib.File.new_for_uri (local_uri);
                    } else {
                        local = GLib.File.new_for_uri ("file://" + local_uri);
                    }

                    if (local.query_exists ()) {
                        if (local_uri.contains ("file://")) {
                            return local_uri;
                        } else {
                            local_uri = "file://" + local_uri;
                            return local_uri;
                        }
                    } else {
                        return uri;
                    }
                } else {
                    return uri;
                }
            }

            set {
                string[] split = value.split (":");
                if (split[0] == "http" || split[0] == "HTTP") {
                    uri = value;
                } else {
                    if (!value.contains ("file://")) {
                        local_uri = """file://""" + value;
                    } else {
                        local_uri = value;
                    }
                }
            }
        }

        //public Episode () {
        //    parent = null;
        //    local_uri = null;
        //    status = EpisodeStatus.UNPLAYED;
        //    current_download_status = DownloadStatus.NOT_DOWNLOADED;
        //    last_played_position = 0;
        //}
        public static int episode_sort_func (Episode item1, Episode item2) {
            return item1.datetime_released.compare (item2.datetime_released) * -1;
        }

        public Episode (
            string title,
            string uri,
            string date_released,
            string description,
            string guid,
            string link
        ) {
            DateTime datetime_released = null;
            if (date_released != null) {
                GLib.Time tm = GLib.Time ();
                tm.strptime (date_released, "%a, %d %b %Y %H:%M:%S %Z");
                datetime_released = new DateTime.local (
                    1900 + tm.year,
                    1 + tm.month,
                    tm.day,
                    tm.hour,
                    tm.minute,
                    tm.second
                );
            }
            Object (
                title: title,
                uri: uri,
                datetime_released: datetime_released,
                description: description,
                guid: guid,
                link: link
            );
        }

        public Episode.from_sqlite_row (Sqlite.Statement stmt)
            throws EpisodeConstructionError.ROW_PARSING_ERROR {
            string title = null;
            string description = null;
            string uri = null;
            string local_uri = null;
            DateTime datetime_released = null;
            DownloadStatus current_download_status =
                DownloadStatus.NOT_DOWNLOADED;
            EpisodeStatus status = EpisodeStatus.PLAYED;
            int64 last_played_position = 0;
            Podcast parent = null;
            string podcast_uri = null;
            string guid = null;
            string link = null;

            for (int i = 0; i < stmt.column_count (); i++) {
                string column_name = stmt.column_name (i) ?? "<none>";
                string val = stmt.column_text (i) ?? "<none>";

                if (column_name == "title") {
                    title = val;
                } else if (column_name == "description") {
                    description = val;
                } else if (column_name == "uri") {
                    uri = val;
                } else if (column_name == "local_uri") {
                    if (val != null) {
                        local_uri = val;
                    }
                } else if (column_name == "released") {
                    int64 datetime = 0;
                    if (int64.try_parse (val, out datetime)) {
                        datetime_released = new GLib.DateTime.from_unix_local (
                            datetime
                        );
                    }
                } else if (column_name == "download_status") {
                    if (val == "downloaded") {
                        current_download_status = DownloadStatus.DOWNLOADED;
                    } else {
                        current_download_status = DownloadStatus.NOT_DOWNLOADED;
                    }
                } else if (column_name == "play_status") {
                    if (val == "played") {
                        status = EpisodeStatus.PLAYED;
                    } else {
                        status = EpisodeStatus.UNPLAYED;
                    }
                } else if (column_name == "latest_position") {
                    int64 position = 0;
                    if (int64.try_parse (val, out position)) {
                        last_played_position = position;
                    }
                } else if (column_name == "parent_podcast_name") {
                    parent = new Podcast.with_name (val);
                } else if (column_name == "podcast_uri") {
                    podcast_uri = val;
                } else if (column_name == "guid") {
                    guid = val;
                } else if (column_name == "link") {
                    link = val;
                }
            }
            if (title == null || description == null || uri == null || local_uri
            == null || datetime_released == null || parent == null ||
            podcast_uri == null || guid == null || link == null) {
                throw new EpisodeConstructionError.ROW_PARSING_ERROR ("Required column was missing");
            }
            Object (
                title: title,
                description: description,
                uri: uri,
                local_uri: local_uri,
                datetime_released: datetime_released,
                current_download_status: current_download_status,
                status: status,
                last_played_position: last_played_position,
                parent: parent,
                podcast_uri: podcast_uri,
                guid: guid,
                link: link
            );
        }
    }

    /*
     * Possible episode playback statuses, either played or unplayed. In Vocal 2.0 it would be
     * beneficial to have an additional value to determine if the episode is finished
     * or simply started.
     */
    public enum EpisodeStatus {
        PLAYED, UNPLAYED;
    }

    /*
     * Possible episode download statuses, either downloaded or not downloaded.
     */
    public enum DownloadStatus {
        DOWNLOADED,
        NOT_DOWNLOADED;
    }
}
