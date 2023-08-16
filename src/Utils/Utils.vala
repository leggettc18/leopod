

namespace Leopod {

public class Utils {
    /*
     * Strips a string of HTML tags, except for ones that are useful in markup
     */
    public static string html_to_markup (string original) {

        string markup = GLib.Uri.unescape_string (original);

        if ( markup == null ) {
            markup = original;
        }

        markup = markup.replace ("&", "&amp;");

        // Simplify (keep only href attribute) & preserve anchor tags.
        Regex simple_links = new Regex ("<a (.*?(href[\\s=]*?\".*?\").*?)>(.*?)<[\\s\\/]*?a[\\s>]*",
                                      RegexCompileFlags.CASELESS | RegexCompileFlags.DOTALL);
        markup = simple_links.replace (markup, -1, 0, "?a? \\2?a-end?\\3 ?/a?");

        // Replace <br> tags with line breaks.
        Regex line_breaks = new Regex ("<br[\\s\\/]*?>", RegexCompileFlags.CASELESS);
        markup = line_breaks.replace (markup, -1, 0, "\n");

        markup = markup.replace ("<a", "?a?");
        markup = markup.replace ("</a>", "?/a?");

        // Preserve bold tags
        markup = markup.replace ("<b>", "?b?");
        markup = markup.replace ("</b>", "?/b?");

        int next_open_bracket_index = 0;
        int next_close_bracket_index = 0;
        while (next_open_bracket_index >= 0) {
            next_open_bracket_index = markup.index_of ("<", 0);
            next_close_bracket_index = markup.index_of (">", next_open_bracket_index) + 1;
            if (
                next_open_bracket_index < next_close_bracket_index && next_open_bracket_index >= 0
                && next_close_bracket_index >= 0
                && next_open_bracket_index <= markup.length
                && next_close_bracket_index <= markup.length
            ) {
                markup = markup.splice (next_open_bracket_index, next_close_bracket_index);
                next_open_bracket_index = 0;
                next_close_bracket_index = 0;
            } else {
                next_open_bracket_index = -1;
            }
        }

        // remaining < & > tags are translated
        markup = markup.replace ("<", "&lt;");
        markup = markup.replace (">", "&gt;");

        // Preserve hyperlinks
        markup = markup.replace ("?a?", "<a");
        markup = markup.replace ("?a-end?", ">");
        markup = markup.replace ("?/a?", "</a>");

        // Preserve bold tags
        markup = markup.replace ("?b?", "<b>");
        markup = markup.replace ("?/b?", "</b>");

        if (markup != null && markup.length > 0)
            return markup;
        else
            return markup;

    }
}
}
