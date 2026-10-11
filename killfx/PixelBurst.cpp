// pulled into KillEffects.cpp anon ns — dont compile alone

void DrawPixelBurst(ImDrawList* dl, const KillFx& fx, const Matrix4x4& vm,
                    const Vector2& vp, float sx, float sy, float t) {
	const float a = 1.0f - t;
	const ImU32 acc = Accent();
	const ImU32 soft = SoftAccent();
	const ImU32 hi = TextCol();

	ImVec2 c;
	if (!Project(vm, vp, sx, sy, fx.origin, c)) return;
	const float sr = ScreenRadius(vm, vp, sx, sy, fx.origin, 3.8f);

	dl->AddCircleFilled(c, sr * 0.22f * (1.0f - t * 0.6f),
	                    MulA(acc, a * 0.35f), 28);
	dl->AddCircleFilled(c, sr * 0.10f * (1.0f - t),
	                    MulA(hi, a * 0.75f), 20);

	for (int i = 0; i < 48; ++i) {
		const float u = Hash11(fx.seed + i * 1.9f);
		const float v = Hash11(fx.seed + i * 2.7f);
		const float w = Hash11(fx.seed + i * 3.3f);
		const float ang = u * 6.2831853f;
		const float elev = (v - 0.5f) * 1.6f;
		const float dist = t * (2.5f + w * 7.5f);
		const float rise = t * (1.0f + v * 3.5f) - t * t * 2.5f;
		Vector3 wp{
			fx.origin.x + std::cos(ang) * dist,
			fx.origin.y + rise + elev * dist * 0.25f,
			fx.origin.z + std::sin(ang) * dist
		};
		ImVec2 sp;
		if (!Project(vm, vp, sx, sy, wp, sp)) continue;

		const float cell = (std::max)(2.5f, sr * 0.09f * (1.0f - t * 0.35f));
		const float pulse = 0.55f + 0.45f * std::sin(t * 18.0f + u * 6.0f);
		ImU32 col = (i % 5 == 0) ? hi : ((i % 2) ? acc : soft);
		col = MulA(col, a * pulse);

		dl->AddRectFilled(ImVec2(sp.x + 1.0f, sp.y + 1.0f),
		                  ImVec2(sp.x + cell + 1.0f, sp.y + cell + 1.0f),
		                  MulA(IM_COL32(0, 0, 0, 255), a * 0.35f));
		dl->AddRectFilled(ImVec2(sp.x, sp.y),
		                  ImVec2(sp.x + cell, sp.y + cell), col);
		dl->AddRect(ImVec2(sp.x, sp.y),
		            ImVec2(sp.x + cell, sp.y + cell),
		            MulA(hi, a * 0.35f), 0.0f, 0, 1.0f);
	}

	for (int r = 0; r < 2; ++r) {
		float u = t * 1.25f - r * 0.18f;
		if (u < 0.f) u = 0.f;
		if (u > 1.f) u = 1.f;
		dl->AddCircle(c, sr * (0.35f + u * 2.1f),
		              MulA(acc, a * (1.0f - u) * 0.85f), 48, 1.5f + (1.0f - u));
	}
}
