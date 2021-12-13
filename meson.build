# project name and programming language
project('com.github.leggettc18.leopod', 'vala', 'c')

# Include the translations module
i18n = import('i18n')

gnome = import('gnome')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

asresources = gnome.compile_resources (
    'as-resources', join_paths('data', 'gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    asresources,
    'src' / 'Application.vala',
    'src' / 'MainWindow.vala',
    'src' / 'Controller.vala',
    'src' / 'Library.vala',
    'src' / 'LeopodSettings.vala',
    'src' / 'GStreamer' / 'Pipeline.vala',
    'src' / 'GStreamer' / 'Playback.vala',
    'src' / 'Utils' / 'SoupClient.vala',
    'src' / 'Utils' / 'FeedParser.vala',
    'src' / 'Utils' / 'XmlUtils.vala',
    'src' / 'Utils' / 'Player.vala',
    'src' / 'Utils' / 'MPRIS.vala',
    'src' / 'Utils' / 'Utils.vala',
    'src' / 'Objects' / 'Podcast.vala',
    'src' / 'Objects' / 'Episode.vala',
    'src' / 'Widgets' / 'CoverArt.vala',
    'src' / 'Widgets' / 'AddPodcastDialog.vala',
    'src' / 'Widgets' / 'EpisodeListItem.vala',
    'src' / 'Widgets' / 'DownloadDetailBox.vala',
    'src' / 'Widgets' / 'DownloadsPopover.vala',
    'src' / 'Widgets' / 'PodcastView.vala',
    'src' / 'Widgets' / 'PlaybackBox.vala',
    'src' / 'Widgets' / 'NewEpisodesView.vala',
    'src' / 'Widgets' / 'ArtworkPopover.vala',
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('gdk-3.0'),
        dependency('libsoup-2.4'),
        dependency('libxml-2.0'),
        dependency('gee-0.8'),
        dependency('sqlite3'),
        dependency('libhandy-1'),
        dependency('gstreamer-1.0')
    ],
    install: true
)

#Translate and install our .desktop file
i18n.merge_file(
    input: 'data' / 'leopod.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: meson.source_root() / 'po',
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications'
)

#Translate and install our .appdata file
i18n.merge_file(
    input: 'data' / 'leopod.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: meson.source_root() / 'po',
    install: true,
    install_dir: get_option('datadir') / 'metainfo'
)

# Install our icons in all the required sizes
icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        'data' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i / 'apps',
        rename: meson.project_name() + '.svg'
    )
    install_data(
        'data' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i + '@2' / 'apps',
        rename: meson.project_name() + '.svg'
    )
endforeach

meson.add_install_script('meson/post_install.py')

subdir('data')

subdir('po')
