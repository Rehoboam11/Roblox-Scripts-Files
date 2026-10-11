#pragma once

// shared guts for killfx — include once inside KillEffects anon ns

static const char* k_fx_names[] = {
	"pixel burst",
	"confetti",
	"shatter",
};
static_assert(sizeof(k_fx_names) / sizeof(k_fx_names[0]) == EffectCount, "names");

static const char* k_hitdata_names[] = {
	"hit type",
	"damage",
	"health left",
	"distance",
	"part name",
};
static_assert(sizeof(k_hitdata_names) / sizeof(k_hitdata_names[0]) == Settings::HITDATA_MODE_COUNT, "hitdata");

struct PendingKill {
	std::uint64_t addr = 0;
	Vector3       pos{};
	double        click_at = 0.0;
	bool          was_alive = false;
};

struct HitWatch {
	std::uint64_t addr = 0;
	float         last_hp = -1.0f;
	double        keep_until = 0.0;
	double        last_fx = 0.0;
	int           part = 0;
	Vector3       point{};
};

struct KillFx {
	int     type = 0;
	Vector3 origin{};
	float   age = 0.0f;
	float   life = 1.25f;
	float   seed = 0.0f;
};

struct Marker {
	Vector3 origin{};
	float   age = 0.0f;
	float   life = 0.55f;
	bool    headshot = false;
};

struct HitText {
	Vector3 origin{};
	float   age = 0.0f;
	float   life = 1.35f;
	bool    headshot = false;
	char    text[64]{};
};

std::vector<PendingKill> g_pending;
std::vector<KillFx>      g_fx;
std::vector<Marker>      g_markers;
std::vector<HitText>     g_texts;
HitWatch                 g_watch{};
bool                     g_lmb_was = false;
double                   g_lmb_at = -1.0;

float Hash11(float n) {
	const float s = std::sin(n * 127.1f) * 43758.5453f;
	return s - std::floor(s);
}

ImU32 MulA(ImU32 c, float a)
{
	int na = (int)((float)((c >> IM_COL32_A_SHIFT) & 0xFF) * a + 0.5f);
	if (na < 0) na = 0;
	if (na > 255) na = 255;
	return (c & ~IM_COL32_A_MASK) | ((ImU32)na << IM_COL32_A_SHIFT);
}

ImU32 LerpU32(ImU32 a, ImU32 b, float t)
{
	if (t < 0.f) t = 0.f;
	if (t > 1.f) t = 1.f;
	auto ch = [](ImU32 c, int sh) { return (int)((c >> sh) & 0xFF); };
	int r = (int)(ch(a, IM_COL32_R_SHIFT) + (ch(b, IM_COL32_R_SHIFT) - ch(a, IM_COL32_R_SHIFT)) * t);
	int g = (int)(ch(a, IM_COL32_G_SHIFT) + (ch(b, IM_COL32_G_SHIFT) - ch(a, IM_COL32_G_SHIFT)) * t);
	int bl = (int)(ch(a, IM_COL32_B_SHIFT) + (ch(b, IM_COL32_B_SHIFT) - ch(a, IM_COL32_B_SHIFT)) * t);
	int al = (int)(ch(a, IM_COL32_A_SHIFT) + (ch(b, IM_COL32_A_SHIFT) - ch(a, IM_COL32_A_SHIFT)) * t);
	return IM_COL32(r, g, bl, al);
}

ImU32 Accent(float a = 1.0f) { return colors::accent_u32(a); }
ImU32 TextCol(float a = 1.0f) { return colors::text_active_u32(a); }
ImU32 SoftAccent(float a = 1.0f) {
	return LerpU32(Accent(a), IM_COL32(255, 255, 255, (int)(255 * a)), 0.35f);
}

bool Project(const Matrix4x4& vm, const Vector2& vp,
             float sx, float sy, const Vector3& p, ImVec2& out) {
	const float w = p.x * vm.m[3][0] + p.y * vm.m[3][1] + p.z * vm.m[3][2] + vm.m[3][3];
	if (w < 0.01f) return false;
	const float inv = 1.0f / w;
	const float x = (p.x * vm.m[0][0] + p.y * vm.m[0][1] + p.z * vm.m[0][2] + vm.m[0][3]) * inv;
	const float y = (p.x * vm.m[1][0] + p.y * vm.m[1][1] + p.z * vm.m[1][2] + vm.m[1][3]) * inv;
	out.x = ((vp.x * 0.5f) + (x * vp.x * 0.5f)) * sx;
	out.y = ((vp.y * 0.5f) - (y * vp.y * 0.5f)) * sy;
	return true;
}

float ScreenRadius(const Matrix4x4& vm, const Vector2& vp,
                   float sx, float sy, const Vector3& origin, float world_r) {
	ImVec2 a, b;
	if (!Project(vm, vp, sx, sy, origin, a)) return 0.0f;
	if (!Project(vm, vp, sx, sy, Vector3{ origin.x + world_r, origin.y, origin.z }, b))
		return 40.0f;
	const float dx = b.x - a.x, dy = b.y - a.y;
	return (std::max)(4.0f, std::sqrt(dx * dx + dy * dy));
}

ImFont* GuiFont() {
	ImFont* f = fonts::selected();
	return f ? f : ImGui::GetFont();
}

const char* PartName(int part) {
	switch (part) {
		case Settings::AIM_HEAD:        return "Head";
		case Settings::AIM_UPPER_TORSO: return "Upper Torso";
		case Settings::AIM_LOWER_TORSO: return "Lower Torso";
		case Settings::AIM_HRP:         return "Root";
		case Settings::AIM_LEFT_HAND:   return "Left Hand";
		case Settings::AIM_RIGHT_HAND:  return "Right Hand";
		case Settings::AIM_LEFT_FOOT:   return "Left Foot";
		case Settings::AIM_RIGHT_FOOT:  return "Right Foot";
		default:                        return "Body";
	}
}

bool IsHead(int part) { return part == Settings::AIM_HEAD; }
bool IsBody(int part) {
	return part == Settings::AIM_UPPER_TORSO
		|| part == Settings::AIM_LOWER_TORSO
		|| part == Settings::AIM_HRP;
}

const char* HitTypeLabel(int part) {
	if (IsHead(part)) return "HEADSHOT";
	if (IsBody(part)) return "BODY SHOT";
	return "LIMB HIT";
}

bool LookupTarget(std::uint64_t addr, Vector3& out_pos, float& out_hp, bool& found) {
	found = false;
	out_hp = 0.0f;
	bool ok = false;
	PlayerHandler::ForEachPlayer([&](const PlayerCache& c) {
		if (c.address != addr) return;
		found = true;
		if (c.humanoidRootPart && g_Memory.IsValid(c.humanoidRootPart->address)) {
			out_pos = BasePart(c.humanoidRootPart->address).GetPosition();
			ok = true;
		}

		else if (c.head && g_Memory.IsValid(c.head->address))
		{
			out_pos = BasePart(c.head->address).GetPosition();
			ok = true;
		}
		if (c.humanoid && g_Memory.IsValid(c.humanoid->address))
			out_hp = Humanoid(c.humanoid->address).GetHealth();
	});
	return ok;
}

void SpawnKill(int type, const Vector3& origin)
{
	KillFx fx;
	fx.type = type;
	fx.origin = origin;
	fx.age = 0.0f;
	fx.seed = (float)ImGui::GetTime() * 17.13f;

	if (type == Confetti)
		fx.life = 1.55f;

	else if (type == Shatter)
		fx.life = 1.20f;

	else
		fx.life = 1.30f; // PixelBurst

	g_fx.push_back(fx);
	if (g_fx.size() > 20)
		g_fx.erase(g_fx.begin());
}

void SpawnMarker(const Vector3& origin, bool headshot)
{
	Marker m;
	m.origin = origin;
	m.age = 0.0f;
	m.life = g_Settings.hitmarker.duration;
	if (m.life < 0.2f)
		m.life = 0.2f;
	m.headshot = headshot;
	g_markers.push_back(m);
	if (g_markers.size() > 32)
		g_markers.erase(g_markers.begin());
}

void FormatHitLine(char* buf, size_t n, int mode, int part,
                   float damage, float hp_left, float dist) {
	switch (mode) {
		case Settings::HITDATA_DAMAGE:
			std::snprintf(buf, n, "-%.0f", damage);
			break;
		case Settings::HITDATA_HEALTH:
			std::snprintf(buf, n, "%.0f HP", (std::max)(0.0f, hp_left));
			break;
		case Settings::HITDATA_DISTANCE:
			std::snprintf(buf, n, "%.0fm", dist);
			break;
		case Settings::HITDATA_PART:
			std::snprintf(buf, n, "%s", PartName(part));
			break;
		case Settings::HITDATA_TYPE:
		default:
			std::snprintf(buf, n, "%s", HitTypeLabel(part));
			break;
	}
}

void SpawnHitTexts(const Vector3& origin, int part, float damage,
                   float hp_left, float dist)
{
	bool headshot = IsHead(part);
	int line = 0;
	for (int m = 0; m < Settings::HITDATA_MODE_COUNT; ++m)
	{
		if (!g_Settings.hitdata.modes[m])
			continue;

		HitText t;
		t.origin = origin;
		t.origin.y += (float)line * 0.45f;
		t.age = 0.0f;
		t.life = g_Settings.hitdata.duration;
		if (t.life < 0.35f)
			t.life = 0.35f;
		t.headshot = headshot;
		FormatHitLine(t.text, sizeof(t.text), m, part, damage, hp_left, dist);
		if (t.text[0] == '\0')
			continue;
		g_texts.push_back(t);
		++line;
	}
	while (g_texts.size() > 36)
		g_texts.erase(g_texts.begin());
}

void DrawPixelBurst(ImDrawList* dl, const KillFx& fx, const Matrix4x4& vm,
                    const Vector2& vp, float sx, float sy, float t);
void DrawConfetti(ImDrawList* dl, const KillFx& fx, const Matrix4x4& vm,
                  const Vector2& vp, float sx, float sy, float t);
void DrawShatter(ImDrawList* dl, const KillFx& fx, const Matrix4x4& vm,
                 const Vector2& vp, float sx, float sy, float t);
void DrawHitmarker(ImDrawList* dl, const Marker& m, const Matrix4x4& vm,
                   const Vector2& vp, float sx, float sy);
void DrawHitText(ImDrawList* dl, const HitText& ht, const Matrix4x4& vm,
                 const Vector2& vp, float sx, float sy);

void DrawKillFx(ImDrawList* dl, const KillFx& fx, const Matrix4x4& vm,
                const Vector2& vp, float sx, float sy)
{
	float t = fx.age / fx.life;
	if (t < 0.f) t = 0.f;
	if (t > 1.f) t = 1.f;

	if (fx.type == Confetti)
		DrawConfetti(dl, fx, vm, vp, sx, sy, t);

	else if (fx.type == Shatter)
		DrawShatter(dl, fx, vm, vp, sx, sy, t);

	else
		DrawPixelBurst(dl, fx, vm, vp, sx, sy, t);
}
