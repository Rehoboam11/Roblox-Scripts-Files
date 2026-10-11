// pulled into KillEffects.cpp anon ns — dont compile alone

void DrawHitmarker(ImDrawList* dl, const Marker& m, const Matrix4x4& vm,
                   const Vector2& vp, float sx, float sy)
{
	float t = m.age / m.life;
	if (t < 0.f) t = 0.f;
	if (t > 1.f) t = 1.f;

	float fade_in = t / 0.08f;
	if (fade_in < 0.f) fade_in = 0.f;
	if (fade_in > 1.f) fade_in = 1.f;

	float fade_out = 1.0f - t;
	float a = fade_in * fade_out;

	ImVec2 c;
	if (!Project(vm, vp, sx, sy, m.origin, c)) return;
	const float base = ScreenRadius(vm, vp, sx, sy, m.origin, 0.55f)
		* (std::max)(0.55f, g_Settings.hitmarker.size);
	const float pop = 1.0f + (1.0f - fade_in) * 0.55f;
	const float s = base * pop;

	const ImU32 acc = m.headshot ? SoftAccent() : Accent();
	const ImU32 hi = TextCol();
	const ImU32 shadow = IM_COL32(0, 0, 0, 180);

	dl->AddCircle(c, s * (1.1f + t * 1.8f), MulA(acc, a * 0.55f), 36, 1.5f);

	const ImVec2 d0(c.x, c.y - s * 0.55f);
	const ImVec2 d1(c.x + s * 0.55f, c.y);
	const ImVec2 d2(c.x, c.y + s * 0.55f);
	const ImVec2 d3(c.x - s * 0.55f, c.y);
	dl->AddQuad(ImVec2(d0.x + 1, d0.y + 1), ImVec2(d1.x + 1, d1.y + 1),
	            ImVec2(d2.x + 1, d2.y + 1), ImVec2(d3.x + 1, d3.y + 1),
	            MulA(shadow, a), 1.5f);
	dl->AddQuad(d0, d1, d2, d3, MulA(acc, a), 1.6f);

	const float gap = s * 0.22f;
	const float arm = s * 0.85f;
	const float th = 2.0f;
	auto arm_line = [&](ImVec2 a0, ImVec2 a1) {
		dl->AddLine(ImVec2(a0.x + 1, a0.y + 1), ImVec2(a1.x + 1, a1.y + 1),
		            MulA(shadow, a), th + 1.0f);
		dl->AddLine(a0, a1, MulA(hi, a), th);
		dl->AddLine(a0, a1, MulA(acc, a * 0.85f), th * 0.55f);
	};
	arm_line(ImVec2(c.x - arm, c.y - arm), ImVec2(c.x - gap, c.y - gap));
	arm_line(ImVec2(c.x + gap, c.y - gap), ImVec2(c.x + arm, c.y - arm));
	arm_line(ImVec2(c.x - arm, c.y + arm), ImVec2(c.x - gap, c.y + gap));
	arm_line(ImVec2(c.x + gap, c.y + gap), ImVec2(c.x + arm, c.y + arm));

	dl->AddCircleFilled(c, s * 0.12f * (1.0f - t * 0.5f), MulA(hi, a * 0.9f), 12);
}
