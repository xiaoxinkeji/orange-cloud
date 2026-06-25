"use client";

import Link from "next/link";
import { useTranslations } from "next-intl";

export default function Error({
	error,
	reset,
}: {
	error: Error & { digest?: string };
	reset: () => void;
}) {
	const t = useTranslations("error");

	const title = t("title");
	const description = t("description");
	const tryAgain = t("tryAgain");
	const backHome = t("backHome");

	return (
		<div
			className="theme-dark"
			style={{
				minHeight: "100dvh",
				display: "flex",
				alignItems: "center",
				justifyContent: "center",
				padding: "24px",
				background: "linear-gradient(180deg, #0c0b10 0%, #120d0a 40%, #0a0a0e 100%)",
			}}
		>
			{/* Ambient glow */}
			<div
				style={{
					position: "fixed",
					left: "50%",
					top: "30%",
					width: "min(600px, 120vw)",
					aspectRatio: "1",
					transform: "translate(-50%, -50%)",
					borderRadius: "50%",
					background:
						"radial-gradient(circle, rgba(244,129,32,0.12) 0%, rgba(244,129,32,0) 70%)",
					pointerEvents: "none",
				}}
			/>

			<div
				className="glass r-island"
				style={{
					position: "relative",
					maxWidth: 480,
					width: "100%",
					padding: "48px 36px",
					textAlign: "center",
				}}
			>
				{/* Error icon */}
				<div
					style={{
						width: 56,
						height: 56,
						margin: "0 auto 24px",
						borderRadius: "50%",
						background: "rgba(244,129,32,0.12)",
						display: "flex",
						alignItems: "center",
						justifyContent: "center",
					}}
				>
					<svg
						width="28"
						height="28"
						viewBox="0 0 24 24"
						fill="none"
						stroke="var(--oc-orange)"
						strokeWidth="2"
						strokeLinecap="round"
						strokeLinejoin="round"
					>
						<circle cx="12" cy="12" r="10" />
						<line x1="12" y1="8" x2="12" y2="12" />
						<line x1="12" y1="16" x2="12.01" y2="16" />
					</svg>
				</div>

				<h1
					className="f-display"
					style={{
						fontSize: 22,
						fontWeight: 700,
						color: "var(--t-primary)",
						margin: "0 0 8px",
					}}
				>
					{title}
				</h1>

				<p
					style={{
						fontSize: 15,
						lineHeight: 1.6,
						color: "var(--t-secondary)",
						margin: "0 0 8px",
					}}
				>
					{description}
				</p>

				{error.digest && (
					<p
						className="f-mono"
						style={{
							fontSize: 12,
							color: "var(--t-tertiary)",
							margin: "0 0 28px",
						}}
					>
						ID: {error.digest}
					</p>
				)}

				{/* Actions */}
				<div
					style={{
						display: "flex",
						flexDirection: "column",
						alignItems: "center",
						gap: 12,
						marginTop: 28,
					}}
				>
					<button
						onClick={reset}
						style={{
							display: "inline-flex",
							alignItems: "center",
							justifyContent: "center",
							gap: 8,
							padding: "12px 32px",
							borderRadius: 999,
							background: "var(--oc-orange)",
							color: "#fff",
							fontSize: 16,
							fontWeight: 600,
							border: "none",
							cursor: "pointer",
							boxShadow: "0 8px 22px rgba(244,129,32,0.34)",
							transition: "background 0.2s ease, transform 0.15s cubic-bezier(0.32,0.72,0,1)",
						}}
						onMouseEnter={(e) => {
							e.currentTarget.style.background = "var(--oc-orange-pressed)";
						}}
						onMouseLeave={(e) => {
							e.currentTarget.style.background = "var(--oc-orange)";
						}}
						onMouseDown={(e) => {
							e.currentTarget.style.transform = "scale(0.97)";
						}}
						onMouseUp={(e) => {
							e.currentTarget.style.transform = "scale(1)";
						}}
					>
						{tryAgain}
					</button>

					<Link
						href="/"
						style={{
							fontSize: 14,
							color: "var(--t-secondary)",
							textDecoration: "none",
							transition: "color 0.2s ease",
						}}
						onMouseEnter={(e) => {
							e.currentTarget.style.color = "var(--t-primary)";
						}}
						onMouseLeave={(e) => {
							e.currentTarget.style.color = "var(--t-secondary)";
						}}
					>
						{backHome}
					</Link>
				</div>
			</div>
		</div>
	);
}
