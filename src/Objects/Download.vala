namespace Leopod {

public errordomain DownloadError {
    FILE_NOT_FOUND, FILE_EXISTS
}

public class Download<T> : Object {
    public string uri { get; construct; }
    public string path { get; construct; }
    public T metadata { get; construct; }
    private FileProgressCallback progress_callback;
    private File local_file;
    private Cancellable cancellable;
    public int64 bytes_total { get; private set; }
    public int64 bytes_downloaded { get; private set; }
    private bool signal_sent = false;
    private double mbps = 0.0;
    private int seconds_elapsed = 0;
    private bool download_complete;

    public double percentage { get {
            return ((1.0 * bytes_downloaded) / bytes_total);
        }
    }
    public int num_secs_remaining {
        get {
            return mbps > 0.0 ? (int) (((bytes_total - bytes_downloaded) / 1000000) / mbps) : 0;
        }
    }

    public signal void completed ();
    public signal void new_percentage_available ();
    public signal void cancelled ();

    public Download (
        string uri,
        string path,
        T? metadata
    ) throws DownloadError.FILE_NOT_FOUND {
        if (!File.new_for_uri (uri).query_exists ()) {
            throw new DownloadError.FILE_NOT_FOUND (
                "No file found at %s".printf (uri)
            );
        }

        Object (uri: uri, path: path, metadata: metadata);
    }

    private void download_delegate (int64 current_num_bytes, int64 total_num_bytes) {
        if (current_num_bytes == total_num_bytes && !signal_sent) {
            completed ();
            signal_sent = true;
            download_complete = true;
            return;
        }
        bytes_downloaded = current_num_bytes;
        bytes_total = total_num_bytes;
        mbps = ((bytes_downloaded) / 1000000) / (seconds_elapsed > 0 ? seconds_elapsed : 1);
        new_percentage_available ();
    }

    public void download () throws DownloadError {
        DirUtils.create_with_parents (Path.get_dirname (path), 0775);
        File remote_file = File.new_for_uri (uri);
        if (!remote_file.query_exists ()) {
            throw new DownloadError.FILE_NOT_FOUND (
                "No file found at %s".printf (uri)
            );
        }
        local_file = File.new_for_path (path);
        progress_callback = download_delegate;
        cancellable = new Cancellable ();
        remote_file.copy_async.begin (
            local_file,
            FileCopyFlags.OVERWRITE,
            Priority.DEFAULT,
            cancellable,
            progress_callback
        );
        Timeout.add (1000, () => {
            seconds_elapsed += 1;
            return !download_complete;
         });
    }

    public void cancel () {
        if (cancellable != null) {
            cancellable.cancel ();
            if (local_file.query_exists ()) {
                try {
                    local_file.delete ();
                } catch (Error e) {
                    error ("Unable to delete file %s".printf (path));
                }
            }
        }
    }
}
}
