extends RefCounted

static func make_tone(frequency: float, duration: float, volume: float = 0.25) -> AudioStreamWAV:
	var mix_rate = 44100
	var sample_count = int(duration * mix_rate)
	var data = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t = float(i) / float(mix_rate)
		var fade = min(1.0, float(sample_count - i) / max(1.0, float(sample_count) * 0.35))
		var sample = int(sin(TAU * frequency * t) * 32767.0 * volume * fade)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream
