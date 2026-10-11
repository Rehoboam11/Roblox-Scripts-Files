// pulled into KillEffects.cpp anon ns — dont compile alone

void DrawHitText(ImDrawList* dl, const HitText& ht, const Matrix4x4& vm,
                 const Vector2& vp, float sx, float sy)
{
	float t = ht.age / ht.life;
	if (t < 0.f) t = 0.f;
	if (t > 1.f) t = 1.f;

	float fade_in = t / 0.08f;
	if (fade_in < 0.f) fade_in = 0.f;
	if (fade_in > 1.f) fade_in = 1.f;

	float fo = (t - 0.6f) / 0.4f;
	if (fo < 0.f) fo = 0.f;
	if (fo > 1.f) fo = 1.f;
	float fade_out = 1.0f - fo;

	float a = fade_in * fade_out;
	if (a <= 0.01f)
		return;

	Vector3 wp = ht.origin;
	wp.y += t * 2.2f;

	ImVec2 sp;
	if (!Project(vm, vp, sx, sy, wp, sp)) return;

	ImFont* font = GuiFont();
	const float fs = fonts::snap_px((std::max)(10.0f, g_Settings.hitdata.size));
	const ImVec2 tsz = font->CalcTextSizeA(fs, FLT_MAX, 0.0f, ht.text);
	const ImVec2 pos(sp.x - tsz.x * 0.5f, sp.y - tsz.y * 0.5f);

	const ImU32 col = ht.headshot
		? SoftAccent(a)
		: colors::text_active_u32(a);
	dl->AddText(font, fs, pos, col, ht.text);
}
