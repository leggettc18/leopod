namespace Leopod {
public class DownloadManager : Object {
    public ObservableArrayList<Download> downloads { get; private set; }
    public double percentage {
        get {
            if (downloads.size > 0 && accumulator > 0) {
                double new_percentage = 0.0;
                foreach (Download download in downloads) {
                    new_percentage += download.percentage;
                }
                for (int i = 0; i < accumulator - downloads.size; i++) {
                    new_percentage += 1.0;
                }
                return new_percentage / (accumulator * 1.0);
            } else {
                return 0.0;
            }
        }
    }
    private uint accumulator = 0;

    public signal void new_percentage_available ();
    public signal void download_added ();
    public signal void download_removed ();

    construct {
        downloads = new ObservableArrayList<Download> ();
    }

    public void add_episode_download (Episode episode) throws DownloadError {
        var download = new Download<Episode> (episode.uri, episode.local_uri, episode);
        download.completed.connect (() => {
            episode.current_download_status = DownloadStatus.DOWNLOADED;
            episode.download_status_changed ();
            downloads.remove (download);
            download_removed ();
            if (downloads.size == 0) {
                accumulator = 0;
            }
        });
        download.cancelled.connect (() => {
            downloads.remove (download);
            if (downloads.size == 0) {
                accumulator = 0;
            }
            download_removed ();
        });
        download.new_percentage_available.connect (() => {
            new_percentage_available ();
        });
        downloads.add (download);
        accumulator += 1;
        download_added ();
        download.download ();
    }
}
}
