namespace Leopod {
public class DownloadsButton : Gtk.Button {
    private Gtk.Overlay overlay;
    private Gtk.Image icon;
    private Gtk.ProgressBar progress_bar;
    private Gtk.Box progress_box;
    private bool progress_bar_visible = false;
    public DownloadManager download_manager { get; construct; }

    public DownloadsButton (DownloadManager download_manager) {
        Object (download_manager: download_manager);
        download_manager.download_added.connect (() => {
            if (!progress_bar_visible) {
                progress_bar_visible = true;
                overlay.add_overlay (progress_box);
            }
        });
        download_manager.download_removed.connect (() => {
            if (progress_bar_visible && download_manager.downloads.size == 0) {
                overlay.remove_overlay (progress_box);
                progress_bar_visible = false;
            }
        });
        download_manager.new_percentage_available.connect (() => {
            progress_bar.set_fraction (download_manager.percentage);
        });
    }

    construct {
        icon = new Gtk.Image.from_icon_name ("browser-download") {
            pixel_size = 24,
        };
        overlay = new Gtk.Overlay () {
            child = icon,
        };
        tooltip_text = _("Downloads");
        child = overlay;
        has_frame = false;
        progress_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            halign = Gtk.Align.FILL,
            valign = Gtk.Align.END,
        };
        progress_bar = new Gtk.ProgressBar () {
            hexpand = true,
        };
        progress_box.append (progress_bar);
    }
}
}
