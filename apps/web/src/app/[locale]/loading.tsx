export default function Loading() {
	return (
		<div
			style={{
				minHeight: "100dvh",
				background: "linear-gradient(180deg, #ffe8d1 0%, #f9f3ea 100%)",
				position: "relative",
				overflow: "hidden",
			}}
		>
			{/* Dawn glow */}
			<div
				style={{
					position: "absolute",
					left: "50%",
					top: "-10%",
					width: "min(800px, 140vw)",
					aspectRatio: "1",
					transform: "translate(-50%, -50%)",
					borderRadius: "50%",
					background:
						"radial-gradient(circle, rgba(255,176,102,0.4) 0%, rgba(255,176,102,0) 70%)",
					pointerEvents: "none",
					animation: "loading-pulse 3s ease-in-out infinite",
				}}
			/>

			<div
				style={{
					position: "relative",
					maxWidth: 1120,
					margin: "0 auto",
					padding: "80px 24px",
				}}
			>
				{/* Header placeholder */}
				<div
					style={{
						display: "flex",
						justifyContent: "space-between",
						alignItems: "center",
						marginBottom: 80,
					}}
				>
					<div
						style={{
							width: 120,
							height: 20,
							borderRadius: 10,
							background: "rgba(0,0,0,0.06)",
							animation: "loading-shimmer 1.8s ease-in-out infinite",
						}}
					/>
					<div style={{ display: "flex", gap: 12 }}>
						<div
							style={{
								width: 64,
								height: 20,
								borderRadius: 10,
								background: "rgba(0,0,0,0.06)",
								animation: "loading-shimmer 1.8s ease-in-out infinite 0.1s",
							}}
						/>
						<div
							style={{
								width: 80,
								height: 32,
								borderRadius: 999,
								background: "rgba(0,0,0,0.06)",
								animation: "loading-shimmer 1.8s ease-in-out infinite 0.2s",
							}}
						/>
					</div>
				</div>

				{/* Hero placeholder */}
				<div style={{ textAlign: "center", marginBottom: 64 }}>
					<div
						className="f-display"
						style={{
							width: "min(480px, 80%)",
							height: 40,
							borderRadius: 12,
							margin: "0 auto 16px",
							background: "rgba(0,0,0,0.07)",
							animation: "loading-shimmer 1.8s ease-in-out infinite 0.15s",
						}}
					/>
					<div
						style={{
							width: "min(360px, 60%)",
							height: 40,
							borderRadius: 12,
							margin: "0 auto 24px",
							background: "rgba(0,0,0,0.07)",
							animation: "loading-shimmer 1.8s ease-in-out infinite 0.25s",
						}}
					/>
					<div
						style={{
							width: "min(320px, 50%)",
							height: 18,
							borderRadius: 9,
							margin: "0 auto 32px",
							background: "rgba(0,0,0,0.05)",
							animation: "loading-shimmer 1.8s ease-in-out infinite 0.35s",
						}}
					/>
					<div
						style={{
							width: 180,
							height: 48,
							borderRadius: 999,
							margin: "0 auto",
							background: "rgba(244,129,32,0.15)",
							animation: "loading-shimmer 1.8s ease-in-out infinite 0.4s",
						}}
					/>
				</div>

				{/* Phone demo placeholder */}
				<div
					style={{
						width: 200,
						height: 420,
						borderRadius: 36,
						margin: "0 auto 80px",
						background: "rgba(0,0,0,0.05)",
						border: "0.5px solid rgba(0,0,0,0.06)",
						animation: "loading-shimmer 1.8s ease-in-out infinite 0.3s",
					}}
				/>

				{/* Feature cards placeholder */}
				<div
					style={{
						display: "grid",
						gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
						gap: 20,
						marginBottom: 64,
					}}
				>
					{[0, 1, 2, 3].map((i) => (
						<div
							key={i}
							className="glass r-island"
							style={{
								padding: "28px 24px",
								animation: `loading-shimmer 1.8s ease-in-out infinite ${0.1 * i + 0.4}s`,
							}}
						>
							<div
								style={{
									width: 36,
									height: 36,
									borderRadius: 10,
									background: "rgba(244,129,32,0.12)",
									marginBottom: 16,
								}}
							/>
							<div
								style={{
									width: "70%",
									height: 16,
									borderRadius: 8,
									background: "rgba(0,0,0,0.06)",
									marginBottom: 8,
								}}
							/>
							<div
								style={{
									width: "90%",
									height: 12,
									borderRadius: 6,
									background: "rgba(0,0,0,0.04)",
								}}
							/>
						</div>
					))}
				</div>
			</div>

			<style>{`
				@keyframes loading-shimmer {
					0%, 100% { opacity: 1; }
					50% { opacity: 0.4; }
				}
				@keyframes loading-pulse {
					0%, 100% { opacity: 0.7; transform: translate(-50%, -50%) scale(1); }
					50% { opacity: 1; transform: translate(-50%, -50%) scale(1.05); }
				}
			`}</style>
		</div>
	);
}
