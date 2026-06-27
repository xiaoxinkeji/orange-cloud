export const APP_STORE_URL = "https://apps.apple.com/app/id6779323783";
export const TESTFLIGHT_URL = "https://testflight.apple.com/join/ZGhbsphj";
/**
 * 上架前临时开关：true 时所有 App Store 徽章显示"审核中"状态。
 * TODO: App Store 审核通过后将此值改为 false，恢复真实下载链接。
 * 所有引用：SiteHeader.tsx、[locale]/page.tsx 的 CTA 区域。
 */
export const APP_STORE_COMING = true;

const APPLE_LOCALE: Record<string, string> = {
  en: "en-us",
  "zh-Hans": "zh-cn",
  "zh-Hant": "zh-tw",
  "zh-HK": "zh-hk",
  ja: "ja-jp",
};

function badgeSrc(locale: string): string {
  const l = APPLE_LOCALE[locale] ?? "en-us";
  return `https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/${l}?size=250x83`;
}

/**
 * App Store 官方本地化徽章。
 * coming=true 时渲染为不可点击的"审核中"状态——官方图片降透明度，下方显示状态标签。
 * 徽章为 Apple 官方本地化黑色徽章 SVG（存 public/appstore/），遵循《营销资源和识别标志指南》。
 */
export default function AppStoreBadge({
  locale = "en",
  alt,
  comingLabel,
  coming = false,
  className = "",
}: {
  locale?: string;
  alt: string;
  comingLabel?: string;
  coming?: boolean;
  className?: string;
}) {
  const src = badgeSrc(locale);

  const img = (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt={alt}
      width={133}
      height={44}
      style={{ height: "44px", width: "auto", display: "block" }}
    />
  );

  if (coming) {
    return (
      <div className={`inline-block cursor-not-allowed select-none ${className}`}>
        <div className="opacity-50">{img}</div>
        {comingLabel && (
          <p className="mt-1.5 flex items-center gap-1.5 text-[11px] t-secondary">
            <span
              className="inline-block h-[5px] w-[5px] animate-pulse rounded-full flex-none"
              style={{ background: "#fbbf24" }}
            />
            {comingLabel}
          </p>
        )}
      </div>
    );
  }

  return (
    <a
      href={APP_STORE_URL}
      className={`inline-block no-underline transition-transform duration-150 ease-out hover:scale-[1.03] active:scale-[0.97] ${className}`}
    >
      {img}
    </a>
  );
}
