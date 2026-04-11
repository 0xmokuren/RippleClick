import AVFoundation

@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private let format: AVAudioFormat
    private var isEngineRunning = false
    private var cachedBuffers: [SoundType: AVAudioPCMBuffer] = [:]

    private init() {
        // swiftlint:disable:next force_unwrapping
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    func playSound(type: SoundType, volume: Float) {
        guard volume > 0 else { return }
        ensureEngineRunning()
        engine.mainMixerNode.outputVolume = volume
        let buffer = cachedBuffers[type] ?? generateAndCacheBuffer(for: type)
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    private func ensureEngineRunning() {
        guard !isEngineRunning else { return }
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func generateAndCacheBuffer(for type: SoundType) -> AVAudioPCMBuffer {
        let buffer = generateBuffer(for: type)
        cachedBuffers[type] = buffer
        return buffer
    }

    private func generateBuffer(for type: SoundType) -> AVAudioPCMBuffer {
        switch type {
        case .waterDrop: return makeBuffer(duration: 0.15, synthesizer: waterDropSample)
        case .pop: return makeBuffer(duration: 0.08, synthesizer: popSample)
        case .sonar: return makeBuffer(duration: 0.2, synthesizer: sonarSample)
        case .bubble: return makeBuffer(duration: 0.12, synthesizer: bubbleSample)
        case .softClick: return makeBuffer(duration: 0.05, synthesizer: softClickSample)
        }
    }

    // MARK: - Buffer generation

    private func makeBuffer(
        duration: Double,
        synthesizer: (_ time: Double, _ duration: Double) -> Float
    ) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let channelData = buffer.floatChannelData?[0]
        else {
            return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 0)
                ?? AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        for sampleIndex in 0..<Int(frameCount) {
            let time = Double(sampleIndex) / sampleRate
            channelData[sampleIndex] = synthesizer(time, duration)
        }
        return buffer
    }

    // MARK: - Sound synthesis

    private func waterDropSample(time: Double, duration: Double) -> Float {
        let progress = time / duration
        let freq = 800.0 - 600.0 * progress
        let envelope = exp(-12.0 * time)
        return Float(sin(2.0 * .pi * freq * time) * envelope)
    }

    private func popSample(time: Double, duration: Double) -> Float {
        let progress = time / duration
        let freq = 400.0 - 100.0 * progress
        let envelope = exp(-20.0 * time)
        return Float(sin(2.0 * .pi * freq * time) * envelope)
    }

    private func sonarSample(time: Double, duration: Double) -> Float {
        let envelope = 1.0 - (time / duration)
        return Float(sin(2.0 * .pi * 1000.0 * time) * envelope)
    }

    private func bubbleSample(time: Double, duration: Double) -> Float {
        let progress = time / duration
        let freq = 300.0 + 600.0 * progress
        let envelope = exp(-8.0 * time)
        return Float(sin(2.0 * .pi * freq * time) * envelope)
    }

    private func softClickSample(time: Double, duration _: Double) -> Float {
        let envelope = exp(-30.0 * time)
        let wave = sin(2.0 * .pi * 800.0 * time) + sin(2.0 * .pi * 850.0 * time)
        return Float(wave * 0.5 * envelope)
    }
}
