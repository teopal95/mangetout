package com.mangetout.service;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.springframework.stereotype.Service;

@Service
public class LinkPreviewService {

    public String fetchOgImage(String url) {
        try {
            Document doc = Jsoup.connect(url)
                    .userAgent("Mozilla/5.0 (compatible; MangetoutBot/1.0)")
                    .timeout(5000)
                    .followRedirects(true)
                    .get();

            for (String selector : new String[]{
                    "meta[property=og:image]",
                    "meta[property=og:image:url]",
                    "meta[name=twitter:image]",
                    "meta[name=twitter:image:src]"
            }) {
                Element el = doc.selectFirst(selector);
                if (el != null) {
                    String content = el.attr("content");
                    if (!content.isBlank()) return content;
                }
            }
        } catch (Exception ignored) {
            // Network errors, timeouts, or sites that block bots — silently skip
        }
        return null;
    }

    public String fetchOgTitle(String url) {
        try {
            Document doc = Jsoup.connect(url)
                    .userAgent("Mozilla/5.0 (compatible; MangetoutBot/1.0)")
                    .timeout(5000)
                    .followRedirects(true)
                    .get();

            for (String selector : new String[]{
                    "meta[property=og:title]",
                    "meta[name=twitter:title]"
            }) {
                Element el = doc.selectFirst(selector);
                if (el != null) {
                    String content = el.attr("content");
                    if (!content.isBlank()) return content;
                }
            }
            // Fallback to <title> tag
            Element title = doc.selectFirst("title");
            return title != null && !title.text().isBlank() ? title.text() : null;
        } catch (Exception ignored) {}
        return null;
    }
}
