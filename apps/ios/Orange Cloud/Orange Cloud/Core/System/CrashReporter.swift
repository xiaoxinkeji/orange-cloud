import MetricKit
import os.log

/// Lightweight crash & diagnostic reporter using Apple MetricKit.
/// MetricKit delivers crash reports, hang reports, and CPU exceptions
/// automatically — no third-party SDK required.
final class CrashReporter: NSObject, MXMetricManagerSubscriber {
    static let shared = CrashReporter()

    private let logger = Logger(subsystem: "jiamin.chen.orange-cloud", category: "CrashReporter")

    private override init() { super.init() }

    func start() {
        MXMetricManager.shared.add(self)
        logger.info("MetricKit subscriber registered")
    }

    // MARK: - MXMetricManagerSubscriber

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            processMetricPayload(payload)
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            processDiagnosticPayload(payload)
        }
    }

    // MARK: - Processing

    private func processMetricPayload(_ payload: MXMetricPayload) {
        logger.info("Received metric payload")

        // Log cellular/network conditions at time of metrics
        if let cellular = payload.cellularConditionMetrics {
            logger.debug("Cellular condition: histogrammed signal=\(cellular.histogrammedCellularConditionTime)")
        }

        // Log animation metrics if available (jank detection)
        if let animation = payload.animationMetrics {
            logger.debug("Animation: scroll hitches=\(animation.scrollHitchTimeRatio)")
        }
    }

    private func processDiagnosticPayload(_ payload: MXDiagnosticPayload) {
        // Crash diagnostics
        if let crashes = payload.crashDiagnostics {
            for diagnostic in crashes {
                logger.error("CRASH: \(diagnostic.callStackTree, privacy: .public)")
                logger.error("  version: \(diagnostic.applicationVersion ?? "unknown", privacy: .public)")
                if let vmInfo = diagnostic.virtualMemoryRegionInfo {
                    logger.error("  virtualMemory: \(vmInfo, privacy: .public)")
                }
            }
        }

        // Hang diagnostics (main thread blocked)
        if let hangs = payload.hangDiagnostics {
            for diagnostic in hangs {
                logger.warning("HANG: duration=\(diagnostic.hangDuration)ms")
                logger.warning("  callStack: \(diagnostic.callStackTree, privacy: .public)")
            }
        }

        // CPU exception diagnostics
        if let cpuExceptions = payload.cpuExceptionDiagnostics {
            for diagnostic in cpuExceptions {
                logger.warning("CPU EXCEPTION: totalCPU=\(diagnostic.totalCPUTime), totalSampled=\(diagnostic.totalSampledTime)")
                logger.warning("  callStack: \(diagnostic.callStackTree, privacy: .public)")
            }
        }
    }
}
