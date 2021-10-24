

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
        Regex simpleLinks = new Regex ("<a (.*?(href[\\s=]*?\".*?\").*?)>(.*?)<[\\s\\/]*?a[\\s>]*",
                                      RegexCompileFlags.CASELESS | RegexCompileFlags.DOTALL);
        markup = simpleLinks.replace (markup, -1, 0, "?a? \\2?a-end?\\3 ?/a?");

        // Replace <br> tags with line breaks.
        Regex lineBreaks = new Regex ("<br[\\s\\/]*?>", RegexCompileFlags.CASELESS);
        markup = lineBreaks.replace (markup, -1, 0, "\n");

        markup = markup.replace ("<a", "?a?");
        markup = markup.replace ("</a>", "?/a?");

        // Preserve bold tags
        markup = markup.replace ("<b>", "?b?");
        markup = markup.replace ("</b>", "?/b?");

        int nextOpenBracketIndex = 0;
        int nextCloseBracketIndex = 0;
        while (nextOpenBracketIndex >= 0) {
            nextOpenBracketIndex = markup.index_of ("<", 0);
            nextCloseBracketIndex = markup.index_of (">", nextOpenBracketIndex) + 1;
            if (
                nextOpenBracketIndex < nextCloseBracketIndex && nextOpenBracketIndex >= 0
                && nextCloseBracketIndex >= 0
                && nextOpenBracketIndex <= markup.length
                && nextCloseBracketIndex <= markup.length
            ) {
                markup = markup.splice (nextOpenBracketIndex, nextCloseBracketIndex);
                nextOpenBracketIndex = 0;
                nextCloseBracketIndex = 0;
            } else {
                nextOpenBracketIndex = -1;
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
