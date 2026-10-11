// pulled into KillEffects.cpp anon ns — dont compile alone

void DrawShatter(ImDrawList* dl, const KillFx& fx, const Matrix4x4& vm,
                 const Vector2& vp, float sx, float sy, float t) {
	const float a = 1.0f - t;
	const ImU32 acc = Accent();
	const ImU32 glass = SoftAccent();
	const ImU32 edge = TextCol();

	ImVec2 c;
	if (!Project(vm, vp, sx, sy, fx.origin, c)) return;
	const float sr = ScreenRadius(vm, vp, sx, sy, fx.origin, 3.6f);

	for (int r = 0; r < 3; ++r) {
		float u = t * 1.5f - r * 0.12f;
		if (u < 0.f) u = 0.f;
		if (u > 1.f) u = 1.f;
		dl->AddCircle(c, sr * (0.2f + u * 2.4f),
		              MulA(acc, a * (1.0f - u) * 0.7f), 40, 1.25f);
	}

	if (t < 0.2f) {
		const float flash = 1.0f - t / 0.2f;
		dl->AddCircleFilled(c, sr * 0.35f * flash, MulA(edge, flash * 0.55f), 24);
	}

	for (int i = 0; i < 22; ++i) {
		const float u = Hash11(fx.seed + i);
		const float v = Hash11(fx.seed + i + 40.f);
		const float w = Hash11(fx.seed + i + 80.f);
		const float ang = u * 6.2831853f;
		const float elev = (v - 0.35f) * 1.4f;
		const float dist = t * (2.0f + w * 6.5f);
		const float fall = t * t * 5.0f;
		Vector3 mid{
			fx.origin.x + std::cos(ang) * dist,
			fx.origin.y + elev * dist - fall,
			fx.origin.z + std::sin(ang) * dist
		};

		ImVec2 sp;
		if (!Project(vm, vp, sx, sy, mid, sp)) continue;

		const float spin = t * (4.0f + u * 6.0f) + ang;
		const float s = sr * (0.18f + v * 0.14f) * (1.0f - t * 0.35f);
		const ImVec2 p0(sp.x + std::cos(spin) * s,
		                sp.y + std::sin(spin) * s);
		const ImVec2 p1(sp.x + std::cos(spin + 2.15f) * s * 0.75f,
		                sp.y + std::sin(spin + 2.15f) * s * 0.75f);
		const ImVec2 p2(sp.x + std::cos(spin - 2.05f) * s * 0.70f,
		                sp.y + std::sin(spin - 2.05f) * s * 0.70f);

		dl->AddTriangleFilled(p0, p1, p2, MulA(glass, a * 0.42f));
		dl->AddTriangle(p0, p1, p2, MulA(edge, a * 0.85f), 1.2f);

		dl->AddLine(p0, p1, MulA(acc, a * 0.65f), 1.0f);
	}
}
