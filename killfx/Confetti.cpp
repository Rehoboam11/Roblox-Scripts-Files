// pulled into KillEffects.cpp anon ns — dont compile alone

void DrawConfetti(ImDrawList* dl, const KillFx& fx, const Matrix4x4& vm,
                  const Vector2& vp, float sx, float sy, float t) {
	const float a = 1.0f - t;
	const ImU32 palette[6] = {
		Accent(), SoftAccent(), TextCol(),
		LerpU32(Accent(), IM_COL32(255, 80, 160, 255), 0.45f),
		LerpU32(Accent(), IM_COL32(80, 255, 200, 255), 0.40f),
		LerpU32(Accent(), IM_COL32(255, 220, 80, 255), 0.50f),
	};

	for (int i = 0; i < 36; ++i) {
		const float u = Hash11(fx.seed + i * 2.3f);
		const float v = Hash11(fx.seed + i * 4.7f);
		const float w = Hash11(fx.seed + i * 6.1f);
		const float ang = u * 6.2831853f;
		const float spd = 4.0f + v * 11.0f;
		const float dist = t * spd;
		const float grav = t * t * 14.0f;
		Vector3 wp{
			fx.origin.x + std::cos(ang) * dist,
			fx.origin.y + t * (5.5f + w * 4.0f) - grav,
			fx.origin.z + std::sin(ang) * dist
		};
		ImVec2 sp;
		if (!Project(vm, vp, sx, sy, wp, sp)) continue;

		const float rot = (u + t * (2.5f + v * 3.0f)) * 6.2831853f;
		const float len = 4.5f + v * 4.0f;
		const float thick = 1.6f + w * 1.4f;
		const ImVec2 d(std::cos(rot) * len, std::sin(rot) * len);
		const ImVec2 n(-std::sin(rot) * thick, std::cos(rot) * thick);

		const ImU32 col = MulA(palette[i % 6], a * (0.75f + 0.25f * (1.0f - t)));

		const ImVec2 p0(sp.x - d.x - n.x, sp.y - d.y - n.y);
		const ImVec2 p1(sp.x + d.x - n.x, sp.y + d.y - n.y);
		const ImVec2 p2(sp.x + d.x + n.x, sp.y + d.y + n.y);
		const ImVec2 p3(sp.x - d.x + n.x, sp.y - d.y + n.y);
		dl->AddQuadFilled(p0, p1, p2, p3, col);
		dl->AddQuad(p0, p1, p2, p3, MulA(IM_COL32(255, 255, 255, 255), a * 0.25f), 1.0f);

		if ((i & 1) == 0)
			dl->AddCircleFilled(sp, 1.4f + (1.0f - t), MulA(TextCol(), a * 0.7f), 8);
	}

	ImVec2 c;
	if (Project(vm, vp, sx, sy, fx.origin, c)) {
		const float sr = ScreenRadius(vm, vp, sx, sy, fx.origin, 2.5f);
		dl->AddCircleFilled(c, sr * 0.15f * (1.0f - t), MulA(Accent(), a * 0.4f), 20);
	}
}
