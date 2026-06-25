import type { MetadataRoute } from "next";
import { routing } from "@/i18n/routing";

const SITE_URL = "https://orange-cloud.chatiro.app";

function urlFor(locale: string, path: string) {
	const prefix = locale === routing.defaultLocale ? "" : `/${locale}`;
	return `${SITE_URL}${prefix}${path}`;
}

export default function sitemap(): MetadataRoute.Sitemap {
	const pages = ["", "/privacy", "/terms", "/contact"];

	return pages.map((path) => ({
		url: urlFor(routing.defaultLocale, path),
		lastModified: new Date(),
		alternates: {
			languages: Object.fromEntries(routing.locales.map((locale) => [locale, urlFor(locale, path)])),
		},
	}));
}
