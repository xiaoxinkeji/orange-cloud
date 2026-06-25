import Link from "next/link";

export default function NotFound() {
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
					top: "35%",
					width: "min(600px, 120vw)",
					aspectRatio: "1",
					transform: "translate(-50%, -50%)",
					borderRadius: "50%",
					background:
						"radial-gradient(circle, rgba(244,129,32,0.1) 0%, rgba(244,129,32,0) 70%)",
					pointerEvents: "none",
				}}
			/>

			<div
				className="glass r-island"
				style={{
					position: "relative",
					maxWidth: 480,
					width: "100%",
					padding: "56px 36px 48px",
					textAlign: "center",
				}}
			>
				{/* 404 number */}
				<h1
					className="f-display"
					style={{
						fontSize: 96,
						fontWeight: 800,
						lineHeight: 1,
						margin: "0 0 16px",
						background: "linear-gradient(180deg, var(--oc-orange) 0%, rgba(244,129,32,0.4) 100%)",
						WebkitBackgroundClip: "text",
						WebkitTextFillColor: "transparent",
						backgroundClip: "text",
					}}
				>
					404
				</h1>

				<p
					className="f-display"
					style={{
						fontSize: 20,
						fontWeight: 600,
						color: "var(--t-primary)",
						margin: "0 0 8px",
					}}
				>
					Page not found
				</p>

				<p
					style={{
						fontSize: 15,
						lineHeight: 1.6,
						color: "var(--t-secondary)",
						margin: "0 0 36px",
					}}
				>
					The page you are looking for does not exist or has been moved.
				</p>

				<Link
					href="/"
					style={{
						display: "inline-flex",
						alignItems: "center",
						gap: 8,
						padding: "12px 32px",
						borderRadius: 999,
						background: "var(--oc-orange)",
						color: "#fff",
						fontSize: 16,
						fontWeight: 600,
						textDecoration: "none",
						boxShadow: "0 8px 22px rgba(244,129,32,0.34)",
						transition: "background 0.2s ease, transform 0.15s cubic-bezier(0.32,0.72,0,1)",
					}}
				>
					<svg
						width="16"
						height="16"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						strokeWidth="2"
						strokeLinecap="round"
						strokeLinejoin="round"
					>
						<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
						<polyline points="9 22 9 12 15 12 15 22" />
					</svg>
					Back to Home
				</Link>
			</div>
		</div>
	);
}
