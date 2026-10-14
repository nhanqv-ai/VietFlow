//
//  RealWorldTypingAndBackspaceTests.swift
//  VietFlowEngineTests
//
//  Requirement R3: Comprehensive Real-World Vietnamese Typing & Backspace Simulation Suite.
//  Simulates a real-world client editor screen buffer (`applyKeystrokesAndBackspacesToScreenBuffer`),
//  evaluating 195 real-world Vietnamese typing, backspacing, and editing scenarios across 7 categories.
//

import Foundation
import VietFlowEngine

// MARK: - Screen Buffer Simulator

/// Faithful simulator of a client text editor receiving keystrokes, Backspaces, and TextDeltas.
/// Models:
/// 1. Physical keystrokes passing through or intercepted by `VietFlowEngine`.
/// 2. `TextDelta.backspaces` deleting characters and `TextDelta.insertText` appending text.
/// 3. Physical Backspace (`<BS>`, `\u{08}`, `\u{7F}`) invoking `engine.handleBackspace()` and deleting 1 screen character.
/// 4. Hard boundaries (`\n`, `\t`, `\u{1B}`) invoking `engine.reset()` and appending to buffer.
/// Enforces:
/// - Zero buffer underruns (`screenBuffer.count >= delta.backspaces`).
/// - Strict Unicode NFC precomposition at every keystroke step.
public func applyKeystrokesAndBackspacesToScreenBuffer(
    _ input: String,
    engine: VietnameseEngineProtocol,
    file: StaticString = #file,
    line: UInt = #line
) -> String {
    let normalizedInput = input.replacingOccurrences(of: "<BS>", with: "\u{08}")
    var screenBuffer = ""
    
    for char in normalizedInput {
        if char == "\u{08}" || char == "\u{7F}" {
            // User pressed physical Backspace
            _ = engine.handleBackspace()
            if !screenBuffer.isEmpty {
                screenBuffer.removeLast()
            }
        } else if char == "\n" || char == "\t" || char == "\u{1B}" {
            // Hard navigation boundary
            engine.reset()
            screenBuffer.append(char)
        } else {
            // Regular printable key
            if let delta = engine.processKey(char) {
                XCTAssertTrue(
                    screenBuffer.count >= delta.backspaces,
                    "Buffer underrun: delta requested \(delta.backspaces) backspaces but screenBuffer only has \(screenBuffer.count) chars! Buffer: '\(screenBuffer)', Key: '\(char)'",
                    file: file,
                    line: line
                )
                let dropCount = min(delta.backspaces, screenBuffer.count)
                if dropCount > 0 {
                    screenBuffer = String(screenBuffer.dropLast(dropCount))
                }
                screenBuffer.append(delta.insertText)
            } else {
                screenBuffer.append(char)
            }
        }
        
        let nfc = screenBuffer.precomposedStringWithCanonicalMapping
        XCTAssertEqual(
            screenBuffer,
            nfc,
            "Unicode normalization violation! Buffer is not strictly NFC after key '\(char)'. Buffer: '\(screenBuffer)'",
            file: file,
            line: line
        )
    }
    
    return screenBuffer
}

// MARK: - RealWorldTypingAndBackspaceTests Suite (195 Scenarios)

public final class RealWorldTypingAndBackspaceTests: VietFlowTestCase {
    private var engine: VietnameseEngineProtocol!
    private var vniEngine: VietnameseEngineProtocol!
    
    public override func setUp() {
        super.setUp()
        engine = makeEngine(inputMethod: .telex, tonePlacement: .modern)
        vniEngine = makeEngine(inputMethod: .vni, tonePlacement: .modern)
    }
    
    @discardableResult
    private func apply(
        _ input: String,
        engine targetEngine: VietnameseEngineProtocol? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> String {
        let eng = targetEngine ?? engine!
        return applyKeystrokesAndBackspacesToScreenBuffer(input, engine: eng, file: file, line: line)
    }
    
    // =========================================================================
    // MARK: - Section 1: All C + w Shorthand Combinations (Telex) (55 tests)
    // =========================================================================
    
    func test_001_cw_standalone_w() {
        XCTAssertEqual(apply("w"), "ư")
    }
    func test_002_cw_standalone_wa() {
        XCTAssertEqual(apply("wa"), "ưa")
    }
    func test_003_cw_standalone_war() {
        XCTAssertEqual(apply("war"), "ửa")
    }
    func test_004_cw_s_sw() {
        XCTAssertEqual(apply("sw"), "sư")
    }
    func test_005_cw_s_swa() {
        XCTAssertEqual(apply("swa"), "sưa")
    }
    func test_006_cw_s_swar() {
        XCTAssertEqual(apply("swar"), "sửa")
    }
    func test_007_cw_s_swax() {
        XCTAssertEqual(apply("swax"), "sữa")
    }
    func test_008_cw_th_thw() {
        XCTAssertEqual(apply("thw"), "thư")
    }
    func test_009_cw_th_thwa() {
        XCTAssertEqual(apply("thwa"), "thưa")
    }
    func test_010_cw_th_thwcj() {
        XCTAssertEqual(apply("thwcj"), "thực")
    }
    func test_011_cw_th_thwr() {
        XCTAssertEqual(apply("thwr"), "thử")
    }
    func test_012_cw_nh_nhw() {
        XCTAssertEqual(apply("nhw"), "như")
    }
    func test_013_cw_nh_nhwa() {
        XCTAssertEqual(apply("nhwa"), "nhưa")
    }
    func test_014_cw_nh_nhwng() {
        XCTAssertEqual(apply("nhwng"), "nhưng")
    }
    func test_015_cw_nh_nhwngx() {
        XCTAssertEqual(apply("nhwngx"), "những")
    }
    func test_016_cw_ch_chw() {
        XCTAssertEqual(apply("chw"), "chư")
    }
    func test_017_cw_ch_chwa() {
        XCTAssertEqual(apply("chwa"), "chưa")
    }
    func test_018_cw_ch_chwx() {
        XCTAssertEqual(apply("chwx"), "chữ")
    }
    func test_019_cw_t_tw() {
        XCTAssertEqual(apply("tw"), "tư")
    }
    func test_020_cw_t_twj() {
        XCTAssertEqual(apply("twj"), "tự")
    }
    func test_021_cw_t_twa() {
        XCTAssertEqual(apply("twa"), "tưa")
    }
    func test_022_cw_t_twowng() {
        XCTAssertEqual(apply("twowng"), "tương")
    }
    func test_023_cw_v_vw() {
        XCTAssertEqual(apply("vw"), "vư")
    }
    func test_024_cw_v_vwa() {
        XCTAssertEqual(apply("vwa"), "vưa")
    }
    func test_025_cw_v_vwaf() {
        XCTAssertEqual(apply("vwaf"), "vừa")
    }
    func test_026_cw_l_lw() {
        XCTAssertEqual(apply("lw"), "lư")
    }
    func test_027_cw_l_lwa() {
        XCTAssertEqual(apply("lwa"), "lưa")
    }
    func test_028_cw_l_lwar() {
        XCTAssertEqual(apply("lwar"), "lửa")
    }
    func test_029_cw_c_cw() {
        XCTAssertEqual(apply("cw"), "cư")
    }
    func test_030_cw_c_cwa() {
        XCTAssertEqual(apply("cwa"), "cưa")
    }
    func test_031_cw_c_cwar() {
        XCTAssertEqual(apply("cwar"), "cửa")
    }
    func test_032_cw_c_cwcj() {
        XCTAssertEqual(apply("cwcj"), "cực")
    }
    func test_033_cw_m_mw() {
        XCTAssertEqual(apply("mw"), "mư")
    }
    func test_034_cw_m_mwa() {
        XCTAssertEqual(apply("mwa"), "mưa")
    }
    func test_035_cw_m_mwaf() {
        XCTAssertEqual(apply("mwaf"), "mừa")
    }
    func test_036_cw_m_mwcj() {
        XCTAssertEqual(apply("mwcj"), "mực")
    }
    func test_037_cw_ng_ngw() {
        XCTAssertEqual(apply("ngw"), "ngư")
    }
    func test_038_cw_ng_ngwaj() {
        XCTAssertEqual(apply("ngwaj"), "ngựa")
    }
    func test_039_cw_ngh_nghw() {
        XCTAssertEqual(apply("nghw"), "nghư")
    }
    func test_040_cw_g_gw() {
        XCTAssertEqual(apply("gw"), "gư")
    }
    func test_041_cw_g_gwir() {
        XCTAssertEqual(apply("gwir"), "gửi")
    }
    func test_042_cw_x_xw() {
        XCTAssertEqual(apply("xw"), "xư")
    }
    func test_043_cw_x_xwa() {
        XCTAssertEqual(apply("xwa"), "xưa")
    }
    func test_044_cw_b_bw() {
        XCTAssertEqual(apply("bw"), "bư")
    }
    func test_045_cw_b_bwa() {
        XCTAssertEqual(apply("bwa"), "bưa")
    }
    func test_046_cw_d_dw() {
        XCTAssertEqual(apply("dw"), "dư")
    }
    func test_047_cw_d_dwa() {
        XCTAssertEqual(apply("dwa"), "dưa")
    }
    func test_048_cw_dd_ddw() {
        XCTAssertEqual(apply("ddw"), "đư")
    }
    func test_049_cw_dd_ddwa() {
        XCTAssertEqual(apply("ddwa"), "đưa")
    }
    func test_050_cw_dd_ddwcj() {
        XCTAssertEqual(apply("ddwcj"), "được")
    }
    func test_051_cw_tr_trw() {
        XCTAssertEqual(apply("trw"), "trư")
    }
    func test_052_cw_tr_trwa() {
        XCTAssertEqual(apply("trwa"), "trưa")
    }
    func test_053_cw_ph_phwa() {
        XCTAssertEqual(apply("phwa"), "phưa")
    }
    func test_054_cw_kh_khwa() {
        XCTAssertEqual(apply("khwa"), "khưa")
    }
    func test_055_cw_h_hwa() {
        XCTAssertEqual(apply("hwa"), "hưa")
    }
    
    // =========================================================================
    // MARK: - Section 2: Free-Order Tone & Delayed Diacritics (35 tests)
    // =========================================================================
    
    func test_056_free_tone_thujwc() {
        XCTAssertEqual(apply("thujwc"), "thực")
    }
    func test_057_free_tone_thajat() {
        XCTAssertEqual(apply("thajat"), "thật")
    }
    func test_058_free_tone_thaajt() {
        XCTAssertEqual(apply("thaajt"), "thật")
    }
    func test_059_free_tone_suxwa() {
        XCTAssertEqual(apply("suxwa"), "sữa")
    }
    func test_060_free_tone_suwxa() {
        XCTAssertEqual(apply("suwxa"), "sữa")
    }
    func test_061_free_tone_mufa() {
        XCTAssertEqual(apply("mufa"), "mùa")
    }
    func test_062_free_tone_muaf() {
        XCTAssertEqual(apply("muaf"), "mùa")
    }
    func test_063_delayed_horn_nguoiwf() {
        XCTAssertEqual(apply("nguoiwf"), "người")
    }
    func test_064_delayed_horn_nguoiw() {
        XCTAssertEqual(apply("nguoiw"), "ngươi")
    }
    func test_065_delayed_horn_tuoiw() {
        XCTAssertEqual(apply("tuoiw"), "tươi")
    }
    func test_066_delayed_horn_cuoiwf() {
        XCTAssertEqual(apply("cuoiwf"), "cười")
    }
    func test_067_delayed_horn_buoiwr() {
        XCTAssertEqual(apply("buoiwr"), "bưởi")
    }
    func test_068_delayed_horn_ruouwj() {
        XCTAssertEqual(apply("ruouwj"), "rượu")
    }
    func test_069_delayed_horn_huouw() {
        XCTAssertEqual(apply("huouw"), "hươu")
    }
    func test_070_delayed_horn_muaw() {
        XCTAssertEqual(apply("muaw"), "mưa")
    }
    func test_071_delayed_horn_chuaw() {
        XCTAssertEqual(apply("chuaw"), "chưa")
    }
    func test_072_delayed_horn_suawr() {
        XCTAssertEqual(apply("suawr"), "sửa")
    }
    func test_073_delayed_horn_luowt() {
        XCTAssertEqual(apply("luowt"), "lượt")
    }
    func test_074_delayed_horn_duowcj() {
        XCTAssertEqual(apply("duowcj"), "được")
    }
    func test_075_delayed_horn_nuowcs() {
        XCTAssertEqual(apply("nuowcs"), "nước")
    }
    func test_076_delayed_circ_nguyene() {
        XCTAssertEqual(apply("nguyene"), "nguyên")
    }
    func test_077_delayed_circ_tienges() {
        XCTAssertEqual(apply("tienges"), "tiếng")
    }
    func test_078_delayed_circ_yene() {
        XCTAssertEqual(apply("yene"), "yên")
    }
    func test_079_delayed_circ_quene() {
        XCTAssertEqual(apply("quene"), "quên")
    }
    func test_080_delayed_circ_muono() {
        XCTAssertEqual(apply("muono"), "muôn")
    }
    func test_081_delayed_circ_cuocoj() {
        XCTAssertEqual(apply("cuocoj"), "cuộc")
    }
    func test_082_delayed_circ_tuoior() {
        XCTAssertEqual(apply("tuoior"), "tuổi")
    }
    func test_083_delayed_circ_buonof() {
        XCTAssertEqual(apply("buonof"), "buồn")
    }
    func test_084_delayed_circ_luataj() {
        XCTAssertEqual(apply("luataj"), "luật")
    }
    func test_085_delayed_d_dods() {
        XCTAssertEqual(apply("dods"), "đó")
    }
    func test_086_delayed_d_dadj() {
        XCTAssertEqual(apply("dadj"), "đạt")
    }
    func test_087_delayed_d_duongdf() {
        XCTAssertEqual(apply("duongdf"), "đường")
    }
    func test_088_delayed_d_dinhd() {
        XCTAssertEqual(apply("dinhd"), "đinh")
    }
    func test_089_vni_free_thu75c() {
        XCTAssertEqual(apply("thu75c", engine: vniEngine), "thực")
    }
    func test_090_vni_free_th65t() {
        XCTAssertEqual(apply("th65t", engine: vniEngine), "thật")
    }
    
    // =========================================================================
    // MARK: - Section 3: Mid-Word Multi-Backspace & Buffer Desync (35 tests)
    // =========================================================================
    
    func test_091_bs_desync_suxa_war() {
        XCTAssertEqual(apply("suxa<BS><BS>war"), "sửa")
    }
    func test_092_bs_desync_thujwc_c() {
        XCTAssertEqual(apply("thujwc<BS>c"), "thực")
    }
    func test_093_bs_desync_thajat_aajt() {
        XCTAssertEqual(apply("thajat<BS><BS>aajt"), "thật")
    }
    func test_094_bs_desync_nguoiwf_owfi() {
        XCTAssertEqual(apply("nguoiwf<BS><BS>owfi"), "người")
    }
    func test_095_bs_desync_nguyene_yeen() {
        XCTAssertEqual(apply("nguyene<BS><BS><BS>yeen"), "nguyên")
    }
    func test_096_bs_desync_dods_s() {
        XCTAssertEqual(apply("dods<BS>os"), "đó")
    }
    func test_097_bs_desync_tieengs_f() {
        XCTAssertEqual(apply("tieengs<BS>gf"), "tiềng")
    }
    func test_098_bs_desync_truwowfng_ng() {
        XCTAssertEqual(apply("truwowfng<BS><BS>ng"), "trường")
    }
    func test_099_bs_desync_dduwowjc_p() {
        XCTAssertEqual(apply("dduwowjc<BS>p"), "đượp")
    }
    func test_100_bs_desync_hoanf_ngf() {
        XCTAssertEqual(apply("hoanf<BS>ngf"), "hoàng")
    }
    func test_101_bs_desync_tieest_m() {
        XCTAssertEqual(apply("tieest<BS><BS>eem"), "tiêm")
    }
    func test_102_bs_desync_toans_f() {
        XCTAssertEqual(apply("toans<BS>nf"), "toàn")
    }
    func test_103_bs_desync_vieetj_n() {
        XCTAssertEqual(apply("vieetj<BS><BS>een"), "viên")
    }
    func test_104_bs_desync_phaaps_t() {
        XCTAssertEqual(apply("phaaps<BS><BS>ast"), "phát")
    }
    func test_105_bs_desync_chaan_u() {
        XCTAssertEqual(apply("chaan<BS>u"), "châu")
    }
    func test_106_bs_desync_mowsi_s() {
        XCTAssertEqual(apply("mowsi<BS>i"), "mới")
    }
    func test_107_bs_desync_nguowfi_m() {
        XCTAssertEqual(apply("nguowfi<BS>m"), "ngườm")
    }
    func test_108_bs_desync_thawngs_m() {
        XCTAssertEqual(apply("thawngs<BS><BS>mz"), "thăm")
    }
    func test_109_bs_desync_ddoojc_ng() {
        XCTAssertEqual(apply("ddoojc<BS>ng"), "động")
    }
    func test_110_bs_desync_laapj_t() {
        XCTAssertEqual(apply("laapj<BS><BS>atj"), "lạt")
    }
    func test_111_bs_desync_ruwjc_c() {
        XCTAssertEqual(apply("ruwjc<BS>c"), "rực")
    }
    func test_112_bs_desync_rowx_j() {
        XCTAssertEqual(apply("rowx<BS>owj"), "rợ")
    }
    func test_113_bs_desync_cowf_s() {
        XCTAssertEqual(apply("cowf<BS>ows"), "cớ")
    }
    func test_114_bs_desync_hoaf_ng() {
        XCTAssertEqual(apply("hoaf<BS>ang"), "hoàng")
    }
    func test_115_bs_desync_muwfng_a() {
        XCTAssertEqual(apply("muwfng<BS><BS>a"), "mừa")
    }
    func test_116_bs_desync_ngayf_n() {
        XCTAssertEqual(apply("ngayf<BS>n"), "ngàn")
    }
    func test_117_bs_desync_phast_m() {
        XCTAssertEqual(apply("phast<BS>m"), "phám")
    }
    func test_118_bs_desync_trieern_t() {
        XCTAssertEqual(apply("trieern<BS>jt"), "triệt")
    }
    func test_119_bs_desync_vuowjt_c() {
        XCTAssertEqual(apply("vuowjt<BS>c"), "vược")
    }
    func test_120_bs_desync_baajc_n() {
        XCTAssertEqual(apply("baajc<BS>n"), "bận")
    }
    func test_121_bs_desync_treen_g() {
        XCTAssertEqual(apply("treen<BS>ng"), "trêng")
    }
    func test_122_bs_desync_neefn_t() {
        XCTAssertEqual(apply("neefn<BS>st"), "nết")
    }
    func test_123_bs_desync_tangr_m() {
        XCTAssertEqual(apply("tangr<BS><BS>m"), "tảm")
    }
    func test_124_bs_desync_booj_t() {
        XCTAssertEqual(apply("boojt<BS>t"), "bột")
    }
    func test_125_bs_desync_gox_j() {
        XCTAssertEqual(apply("gox<BS>oj"), "gọ")
    }
    
    // =========================================================================
    // MARK: - Section 4: Full-Word Backspace Deletion & Fresh Word Retyping (25 tests)
    // =========================================================================
    
    func test_126_full_bs_muaf_clean() {
        XCTAssertEqual(apply("muaf<BS><BS><BS><BS>muaf"), "mùa")
    }
    func test_127_full_bs_swar_clean() {
        XCTAssertEqual(apply("swar<BS><BS><BS>swar"), "sửa")
    }
    func test_128_full_bs_thajat_clean() {
        XCTAssertEqual(apply("thajat<BS><BS><BS><BS>thajat"), "thật")
    }
    func test_129_full_bs_vieetj_clean() {
        XCTAssertEqual(apply("vieetj<BS><BS><BS><BS>vieetj"), "việt")
    }
    func test_130_full_bs_over_backspace() {
        XCTAssertEqual(apply("abc<BS><BS><BS><BS><BS><BS><BS><BS><BS><BS>toans"), "toán")
    }
    func test_131_full_bs_nguoiwf_clean() {
        XCTAssertEqual(apply("nguoiwf<BS><BS><BS><BS><BS>nguoiwf"), "người")
    }
    func test_132_full_bs_nguyene_clean() {
        XCTAssertEqual(apply("nguyene<BS><BS><BS><BS><BS><BS>nguyene"), "nguyên")
    }
    func test_133_full_bs_dods_clean() {
        XCTAssertEqual(apply("dods<BS><BS>dods"), "đó")
    }
    func test_134_full_bs_pattern_clean() {
        XCTAssertEqual(apply("pattern<BS><BS><BS><BS><BS><BS><BS>pattern"), "pattern")
    }
    func test_135_full_bs_switch_to_sua() {
        XCTAssertEqual(apply("switch<BS><BS><BS><BS><BS><BS>swar"), "sửa")
    }
    func test_136_full_bs_tieng_to_chan() {
        XCTAssertEqual(apply("tieengs<BS><BS><BS><BS><BS>chaan"), "chân")
    }
    func test_137_full_bs_hoa_to_binh() {
        XCTAssertEqual(apply("hoaf<BS><BS><BS>bifnh"), "bình")
    }
    func test_138_full_bs_doc_to_lap() {
        XCTAssertEqual(apply("ddoojc<BS><BS><BS>laapj"), "lập")
    }
    func test_139_full_bs_cong_to_nghe() {
        XCTAssertEqual(apply("coong<BS><BS><BS><BS>ngheej"), "nghệ")
    }
    func test_140_full_bs_thong_to_tin() {
        XCTAssertEqual(apply("thoong<BS><BS><BS><BS><BS>tin"), "tin")
    }
    func test_141_full_bs_phat_to_trien() {
        XCTAssertEqual(apply("phast<BS><BS><BS><BS>trieern"), "triển")
    }
    func test_142_full_bs_vuot_to_bac() {
        XCTAssertEqual(apply("vuowjt<BS><BS><BS><BS>baajc"), "bậc")
    }
    func test_143_full_bs_tren_to_nen() {
        XCTAssertEqual(apply("treen<BS><BS><BS><BS>neefn"), "nền")
    }
    func test_144_full_bs_tang_to_may() {
        XCTAssertEqual(apply("tangr<BS><BS><BS><BS>mays"), "máy")
    }
    func test_145_full_bs_tinh_to_mac() {
        XCTAssertEqual(apply("tisnh<BS><BS><BS><BS>Mac"), "Mac")
    }
    func test_146_full_bs_bo_to_go() {
        XCTAssertEqual(apply("booj<BS><BS>gox"), "gõ")
    }
    func test_147_full_bs_the_to_he() {
        XCTAssertEqual(apply("thees<BS><BS><BS>heej"), "hệ")
    }
    func test_148_full_bs_moi_to_hoat() {
        XCTAssertEqual(apply("mowsi<BS><BS><BS>hoatj"), "hoạt")
    }
    func test_149_full_bs_dong_to_muot() {
        XCTAssertEqual(apply("ddoojng<BS><BS><BS><BS>muowjt"), "mượt")
    }
    func test_150_full_bs_khong_to_bi() {
        XCTAssertEqual(apply("khoong<BS><BS><BS><BS><BS>bij"), "bị")
    }
    
    // =========================================================================
    // MARK: - Section 5: Word-Boundary Backspace Across Spaces (20 tests)
    // =========================================================================
    
    func test_151_boundary_space_ha_noi_i() {
        XCTAssertEqual(apply("haf nooji <BS><BS>i"), "hà nội")
    }
    func test_152_boundary_space_ha_noi_is() {
        XCTAssertEqual(apply("haf nooji <BS><BS>is"), "hà nối")
    }
    func test_153_boundary_space_ha_noi_ix() {
        XCTAssertEqual(apply("haf nooji <BS><BS>ix"), "hà nỗi")
    }
    func test_154_boundary_space_ha_noi_ir() {
        XCTAssertEqual(apply("haf nooji <BS><BS>ir"), "hà nổi")
    }
    func test_155_boundary_space_ha_noi_ij() {
        XCTAssertEqual(apply("haf nooji <BS><BS>ij"), "hà nội")
    }
    func test_156_boundary_space_viet_nam_nhat() {
        XCTAssertEqual(apply("vieetj nam <BS><BS><BS><BS>nhaatj"), "việt nhật")
    }
    func test_157_boundary_space_hoa_binh_hop() {
        XCTAssertEqual(apply("hoaf bifnh <BS><BS><BS><BS><BS>hopj"), "hòa họp")
    }
    func test_158_boundary_space_cong_ly_minh() {
        XCTAssertEqual(apply("coong lys <BS><BS><BS>minh"), "công minh")
    }
    func test_159_boundary_space_doc_lap_thien() {
        XCTAssertEqual(apply("ddoojc laapj <BS><BS><BS><BS>thieenj"), "độc thiện")
    }
    func test_160_boundary_space_tu_do_quyen() {
        XCTAssertEqual(apply("tuwj do <BS><BS><BS>quyeefn"), "tự quyền")
    }
    func test_161_boundary_space_mua_thu_dong() {
        XCTAssertEqual(apply("muaf thu <BS><BS><BS><BS>ddoong"), "mùa đông")
    }
    func test_162_boundary_space_cay_com_bang() {
        XCTAssertEqual(apply("caay cowm <BS><BS><BS><BS>bangf"), "cây bàng")
    }
    func test_163_boundary_space_pho_xua_phuong() {
        XCTAssertEqual(apply("phoos xuwa <BS><BS><BS><BS>phuwowfng"), "phố phường")
    }
    func test_164_boundary_space_nha_co_kinh() {
        XCTAssertEqual(apply("nhaf coor <BS><BS><BS>kisnh"), "nhà kính")
    }
    func test_165_boundary_space_mai_ngoi_do() {
        XCTAssertEqual(apply("mais ngois <BS><BS><BS><BS><BS>ddoor"), "mái đổ")
    }
    func test_166_boundary_hard_tab_ha_noi() {
        XCTAssertEqual(apply("haf nooji\t<BS><BS>s"), "hà nộs")
    }
    func test_167_boundary_hard_newline_ha_noi() {
        XCTAssertEqual(apply("haf nooji\n<BS><BS>s"), "hà nộs")
    }
    func test_168_boundary_hard_escape_ha_noi() {
        XCTAssertEqual(apply("haf nooji\u{1B}<BS><BS>s"), "hà nộs")
    }
    func test_169_boundary_hard_newline_viet() {
        XCTAssertEqual(apply("vieetj\n<BS>a"), "việta")
    }
    func test_170_boundary_hard_tab_toi() {
        XCTAssertEqual(apply("toois\t<BS>b"), "tốib")
    }
    
    // =========================================================================
    // MARK: - Section 6: Smart English Auto-Restore & Medials (15 tests)
    // =========================================================================
    
    func test_171_english_pattern() {
        XCTAssertEqual(apply("pattern"), "pattern")
    }
    func test_172_english_letter() {
        XCTAssertEqual(apply("letter"), "letter")
    }
    func test_173_english_button() {
        XCTAssertEqual(apply("button"), "button")
    }
    func test_174_english_buffer() {
        XCTAssertEqual(apply("buffer"), "buffer")
    }
    func test_175_english_better() {
        XCTAssertEqual(apply("better"), "better")
    }
    func test_176_english_common() {
        XCTAssertEqual(apply("common"), "common")
    }
    func test_177_english_matter() {
        XCTAssertEqual(apply("matter"), "matter")
    }
    func test_178_english_swim() {
        XCTAssertEqual(apply("swim"), "swim")
    }
    func test_179_english_switch() {
        XCTAssertEqual(apply("switch"), "switch")
    }
    func test_180_english_swift() {
        XCTAssertEqual(apply("swift"), "swift")
    }
    func test_181_english_sweet() {
        XCTAssertEqual(apply("sweet"), "sweet")
    }
    func test_182_english_swap() {
        XCTAssertEqual(apply("swap"), "swap")
    }
    func test_183_english_swing() {
        XCTAssertEqual(apply("swing"), "swing")
    }
    func test_184_english_string() {
        XCTAssertEqual(apply("string"), "string")
    }
    func test_185_english_system() {
        XCTAssertEqual(apply("system"), "system")
    }
    
    // =========================================================================
    // MARK: - Section 7: Full Paragraph Real-World Benchmarks (10 tests)
    // =========================================================================
    
    func test_186_benchmark_p1_clean_telex() {
        let input = "haf nooji muaf thu caay cowm nguooji vangf caay bangf las ddor, nawmf keef been nhau phoos xuwa nhaf coor mais ngois thaam naau"
        let expected = "hà nội mùa thu cây cơm nguội vàng cây bàng lá đỏ, nằm kề bên nhau phố xưa nhà cổ mái ngói thâm nâu"
        XCTAssertEqual(apply(input), expected)
    }
    
    func test_187_benchmark_p1_typos_telex() {
        let input = "hafs<BS><BS>haf nooji muaff<BS><BS>af thu caay cowmm<BS> nguooji vangf caay bangf las ddor, nawmf keef been nhau phoos xuwa nhaf coor mais ngois thaam naau"
        let expected = "hà nội mùa thu cây cơm nguội vàng cây bàng lá đỏ, nằm kề bên nhau phố xưa nhà cổ mái ngói thâm nâu"
        XCTAssertEqual(apply(input), expected)
    }
    
    func test_188_benchmark_p2_clean_telex() {
        let input = "tooi gox thwr thajat nhieeuf pattern khacs nhau maf nguoiwf vieetj hay gox, vaf twf dods ddeef xuaats cachs fix toois uwu nhaats"
        let expected = "tôi gõ thử thật nhiều pattern khác nhau mà người việt hay gõ, và từ đó đề xuất cách fix tối ưu nhất"
        XCTAssertEqual(apply(input), expected)
    }
    
    func test_189_benchmark_p2_typos_telex() {
        let input = "tooi gox thwr thajat nhieeuf patterrn<BS><BS>n khacs nhau maf nguoiwf vieetj hay gox, vaf twf dods<BS><BS>dods ddeef xuaats cachs fix toois uwu nhaats"
        let expected = "tôi gõ thử thật nhiều pattern khác nhau mà người việt hay gõ, và từ đó đề xuất cách fix tối ưu nhất"
        XCTAssertEqual(apply(input), expected)
    }
    
    func test_190_benchmark_p1_clean_vni() {
        let input = "ha2 no65i mu2a thu ca6y co7m nguo65i va2ng ca6y ba2ng la1 d9o3, na82m ke62 be6n nhau pho61 xu7a nha2 co63 ma1i ngo1i tha6m na6u"
        let expected = "hà nội mùa thu cây cơm nguội vàng cây bàng lá đỏ, nằm kề bên nhau phố xưa nhà cổ mái ngói thâm nâu"
        XCTAssertEqual(apply(input, engine: vniEngine), expected)
    }
    
    func test_191_benchmark_p1_typos_vni() {
        let input = "ha1<BS><BS>ha2 no65i mu2a thu ca6y co7mm<BS> nguo65i va2ng ca6y ba2ng la1 d9o3, na82m ke62 be6n nhau pho61 xu7a nha2 co63 ma1i ngo1i tha6m na6u"
        let expected = "hà nội mùa thu cây cơm nguội vàng cây bàng lá đỏ, nằm kề bên nhau phố xưa nhà cổ mái ngói thâm nâu"
        XCTAssertEqual(apply(input, engine: vniEngine), expected)
    }
    
    func test_192_benchmark_p2_clean_vni() {
        let input = "to6i go4 thu73 tha65t nhie62u pattern kha1c nhau ma2 ngu7o7i2 vie65t hay go4, va2 tu72 d9o1 d9e62 xua61t ca1ch fix to61i u7u nha61t"
        let expected = "tôi gõ thử thật nhiều pattern khác nhau mà người việt hay gõ, và từ đó đề xuất cách fix tối ưu nhất"
        XCTAssertEqual(apply(input, engine: vniEngine), expected)
    }
    
    func test_193_benchmark_p2_typos_vni() {
        let input = "to6i go4 thu73 tha65t nhie62u patterrn<BS><BS>n kha1c nhau ma2 ngu7o7i2 vie65t hay go4, va2 tu72 d9o1 d9e62 xua61t ca1ch fix to61i u7u nha61t"
        let expected = "tôi gõ thử thật nhiều pattern khác nhau mà người việt hay gõ, và từ đó đề xuất cách fix tối ưu nhất"
        XCTAssertEqual(apply(input, engine: vniEngine), expected)
    }
    
    func test_194_benchmark_combined_clean_telex() {
        let input = "haf nooji muaf thu, tooi gox thwr pattern vaf twf dods ddeef xuaats cachs fix toois uwu nhaats"
        let expected = "hà nội mùa thu, tôi gõ thử pattern và từ đó đề xuất cách fix tối ưu nhất"
        XCTAssertEqual(apply(input), expected)
    }
    
    func test_195_benchmark_combined_typos_telex() {
        let input = "hafs<BS><BS>haf nooji muaf thu, tooi gox thwr pattern vaf twf dods<BS><BS>dods ddeef xuaats cachs fix toois uwu nhaats"
        let expected = "hà nội mùa thu, tôi gõ thử pattern và từ đó đề xuất cách fix tối ưu nhất"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 8: Multi-Order Permutations for "mới" & Single-'w' "ươ" (10 tests)
    // =========================================================================

    func test_196_moi_moiws() {
        XCTAssertEqual(apply("moiws"), "mới")
    }
    func test_197_moi_mowis() {
        XCTAssertEqual(apply("mowis"), "mới")
    }
    func test_198_moi_mowsi() {
        XCTAssertEqual(apply("mowsi"), "mới")
    }
    func test_199_moi_moisw() {
        XCTAssertEqual(apply("moisw"), "mới")
    }
    func test_200_moi_mosiw() {
        XCTAssertEqual(apply("mosiw"), "mới")
    }
    func test_201_moi_moswi() {
        XCTAssertEqual(apply("moswi"), "mới")
    }
    func test_202_sentence_ngay_xa_xua_moiws() {
        XCTAssertEqual(apply("ngayf xa xuwa khi tooi moiws"), "ngày xa xưa khi tôi mới")
    }
    func test_203_single_w_nguwoif() {
        XCTAssertEqual(apply("nguwoif"), "người")
    }
    func test_204_single_w_truwongf() {
        XCTAssertEqual(apply("truwongf"), "trường")
    }
    func test_205_single_w_dduwocj() {
        XCTAssertEqual(apply("dduwocj"), "được")
    }
    
    // MARK: - Test Registry (205 Tests)
    
    public override var allTests: [(name: String, test: TestMethod)] {
        return [
            // Section 1: All C + w Shorthand Combinations (55 tests)
            ("test_001_cw_standalone_w", test_001_cw_standalone_w),
            ("test_002_cw_standalone_wa", test_002_cw_standalone_wa),
            ("test_003_cw_standalone_war", test_003_cw_standalone_war),
            ("test_004_cw_s_sw", test_004_cw_s_sw),
            ("test_005_cw_s_swa", test_005_cw_s_swa),
            ("test_006_cw_s_swar", test_006_cw_s_swar),
            ("test_007_cw_s_swax", test_007_cw_s_swax),
            ("test_008_cw_th_thw", test_008_cw_th_thw),
            ("test_009_cw_th_thwa", test_009_cw_th_thwa),
            ("test_010_cw_th_thwcj", test_010_cw_th_thwcj),
            ("test_011_cw_th_thwr", test_011_cw_th_thwr),
            ("test_012_cw_nh_nhw", test_012_cw_nh_nhw),
            ("test_013_cw_nh_nhwa", test_013_cw_nh_nhwa),
            ("test_014_cw_nh_nhwng", test_014_cw_nh_nhwng),
            ("test_015_cw_nh_nhwngx", test_015_cw_nh_nhwngx),
            ("test_016_cw_ch_chw", test_016_cw_ch_chw),
            ("test_017_cw_ch_chwa", test_017_cw_ch_chwa),
            ("test_018_cw_ch_chwx", test_018_cw_ch_chwx),
            ("test_019_cw_t_tw", test_019_cw_t_tw),
            ("test_020_cw_t_twj", test_020_cw_t_twj),
            ("test_021_cw_t_twa", test_021_cw_t_twa),
            ("test_022_cw_t_twowng", test_022_cw_t_twowng),
            ("test_023_cw_v_vw", test_023_cw_v_vw),
            ("test_024_cw_v_vwa", test_024_cw_v_vwa),
            ("test_025_cw_v_vwaf", test_025_cw_v_vwaf),
            ("test_026_cw_l_lw", test_026_cw_l_lw),
            ("test_027_cw_l_lwa", test_027_cw_l_lwa),
            ("test_028_cw_l_lwar", test_028_cw_l_lwar),
            ("test_029_cw_c_cw", test_029_cw_c_cw),
            ("test_030_cw_c_cwa", test_030_cw_c_cwa),
            ("test_031_cw_c_cwar", test_031_cw_c_cwar),
            ("test_032_cw_c_cwcj", test_032_cw_c_cwcj),
            ("test_033_cw_m_mw", test_033_cw_m_mw),
            ("test_034_cw_m_mwa", test_034_cw_m_mwa),
            ("test_035_cw_m_mwaf", test_035_cw_m_mwaf),
            ("test_036_cw_m_mwcj", test_036_cw_m_mwcj),
            ("test_037_cw_ng_ngw", test_037_cw_ng_ngw),
            ("test_038_cw_ng_ngwaj", test_038_cw_ng_ngwaj),
            ("test_039_cw_ngh_nghw", test_039_cw_ngh_nghw),
            ("test_040_cw_g_gw", test_040_cw_g_gw),
            ("test_041_cw_g_gwir", test_041_cw_g_gwir),
            ("test_042_cw_x_xw", test_042_cw_x_xw),
            ("test_043_cw_x_xwa", test_043_cw_x_xwa),
            ("test_044_cw_b_bw", test_044_cw_b_bw),
            ("test_045_cw_b_bwa", test_045_cw_b_bwa),
            ("test_046_cw_d_dw", test_046_cw_d_dw),
            ("test_047_cw_d_dwa", test_047_cw_d_dwa),
            ("test_048_cw_dd_ddw", test_048_cw_dd_ddw),
            ("test_049_cw_dd_ddwa", test_049_cw_dd_ddwa),
            ("test_050_cw_dd_ddwcj", test_050_cw_dd_ddwcj),
            ("test_051_cw_tr_trw", test_051_cw_tr_trw),
            ("test_052_cw_tr_trwa", test_052_cw_tr_trwa),
            ("test_053_cw_ph_phwa", test_053_cw_ph_phwa),
            ("test_054_cw_kh_khwa", test_054_cw_kh_khwa),
            ("test_055_cw_h_hwa", test_055_cw_h_hwa),
            
            // Section 2: Free-Order Tone & Delayed Diacritics (35 tests)
            ("test_056_free_tone_thujwc", test_056_free_tone_thujwc),
            ("test_057_free_tone_thajat", test_057_free_tone_thajat),
            ("test_058_free_tone_thaajt", test_058_free_tone_thaajt),
            ("test_059_free_tone_suxwa", test_059_free_tone_suxwa),
            ("test_060_free_tone_suwxa", test_060_free_tone_suwxa),
            ("test_061_free_tone_mufa", test_061_free_tone_mufa),
            ("test_062_free_tone_muaf", test_062_free_tone_muaf),
            ("test_063_delayed_horn_nguoiwf", test_063_delayed_horn_nguoiwf),
            ("test_064_delayed_horn_nguoiw", test_064_delayed_horn_nguoiw),
            ("test_065_delayed_horn_tuoiw", test_065_delayed_horn_tuoiw),
            ("test_066_delayed_horn_cuoiwf", test_066_delayed_horn_cuoiwf),
            ("test_067_delayed_horn_buoiwr", test_067_delayed_horn_buoiwr),
            ("test_068_delayed_horn_ruouwj", test_068_delayed_horn_ruouwj),
            ("test_069_delayed_horn_huouw", test_069_delayed_horn_huouw),
            ("test_070_delayed_horn_muaw", test_070_delayed_horn_muaw),
            ("test_071_delayed_horn_chuaw", test_071_delayed_horn_chuaw),
            ("test_072_delayed_horn_suawr", test_072_delayed_horn_suawr),
            ("test_073_delayed_horn_luowt", test_073_delayed_horn_luowt),
            ("test_074_delayed_horn_duowcj", test_074_delayed_horn_duowcj),
            ("test_075_delayed_horn_nuowcs", test_075_delayed_horn_nuowcs),
            ("test_076_delayed_circ_nguyene", test_076_delayed_circ_nguyene),
            ("test_077_delayed_circ_tienges", test_077_delayed_circ_tienges),
            ("test_078_delayed_circ_yene", test_078_delayed_circ_yene),
            ("test_079_delayed_circ_quene", test_079_delayed_circ_quene),
            ("test_080_delayed_circ_muono", test_080_delayed_circ_muono),
            ("test_081_delayed_circ_cuocoj", test_081_delayed_circ_cuocoj),
            ("test_082_delayed_circ_tuoior", test_082_delayed_circ_tuoior),
            ("test_083_delayed_circ_buonof", test_083_delayed_circ_buonof),
            ("test_084_delayed_circ_luataj", test_084_delayed_circ_luataj),
            ("test_085_delayed_d_dods", test_085_delayed_d_dods),
            ("test_086_delayed_d_dadj", test_086_delayed_d_dadj),
            ("test_087_delayed_d_duongdf", test_087_delayed_d_duongdf),
            ("test_088_delayed_d_dinhd", test_088_delayed_d_dinhd),
            ("test_089_vni_free_thu75c", test_089_vni_free_thu75c),
            ("test_090_vni_free_th65t", test_090_vni_free_th65t),
            
            // Section 3: Mid-Word Multi-Backspace & Buffer Desync (35 tests)
            ("test_091_bs_desync_suxa_war", test_091_bs_desync_suxa_war),
            ("test_092_bs_desync_thujwc_c", test_092_bs_desync_thujwc_c),
            ("test_093_bs_desync_thajat_aajt", test_093_bs_desync_thajat_aajt),
            ("test_094_bs_desync_nguoiwf_owfi", test_094_bs_desync_nguoiwf_owfi),
            ("test_095_bs_desync_nguyene_yeen", test_095_bs_desync_nguyene_yeen),
            ("test_096_bs_desync_dods_s", test_096_bs_desync_dods_s),
            ("test_097_bs_desync_tieengs_f", test_097_bs_desync_tieengs_f),
            ("test_098_bs_desync_truwowfng_ng", test_098_bs_desync_truwowfng_ng),
            ("test_099_bs_desync_dduwowjc_p", test_099_bs_desync_dduwowjc_p),
            ("test_100_bs_desync_hoanf_ngf", test_100_bs_desync_hoanf_ngf),
            ("test_101_bs_desync_tieest_m", test_101_bs_desync_tieest_m),
            ("test_102_bs_desync_toans_f", test_102_bs_desync_toans_f),
            ("test_103_bs_desync_vieetj_n", test_103_bs_desync_vieetj_n),
            ("test_104_bs_desync_phaaps_t", test_104_bs_desync_phaaps_t),
            ("test_105_bs_desync_chaan_u", test_105_bs_desync_chaan_u),
            ("test_106_bs_desync_mowsi_s", test_106_bs_desync_mowsi_s),
            ("test_107_bs_desync_nguowfi_m", test_107_bs_desync_nguowfi_m),
            ("test_108_bs_desync_thawngs_m", test_108_bs_desync_thawngs_m),
            ("test_109_bs_desync_ddoojc_ng", test_109_bs_desync_ddoojc_ng),
            ("test_110_bs_desync_laapj_t", test_110_bs_desync_laapj_t),
            ("test_111_bs_desync_ruwjc_c", test_111_bs_desync_ruwjc_c),
            ("test_112_bs_desync_rowx_j", test_112_bs_desync_rowx_j),
            ("test_113_bs_desync_cowf_s", test_113_bs_desync_cowf_s),
            ("test_114_bs_desync_hoaf_ng", test_114_bs_desync_hoaf_ng),
            ("test_115_bs_desync_muwfng_a", test_115_bs_desync_muwfng_a),
            ("test_116_bs_desync_ngayf_n", test_116_bs_desync_ngayf_n),
            ("test_117_bs_desync_phast_m", test_117_bs_desync_phast_m),
            ("test_118_bs_desync_trieern_t", test_118_bs_desync_trieern_t),
            ("test_119_bs_desync_vuowjt_c", test_119_bs_desync_vuowjt_c),
            ("test_120_bs_desync_baajc_n", test_120_bs_desync_baajc_n),
            ("test_121_bs_desync_treen_g", test_121_bs_desync_treen_g),
            ("test_122_bs_desync_neefn_t", test_122_bs_desync_neefn_t),
            ("test_123_bs_desync_tangr_m", test_123_bs_desync_tangr_m),
            ("test_124_bs_desync_booj_t", test_124_bs_desync_booj_t),
            ("test_125_bs_desync_gox_j", test_125_bs_desync_gox_j),
            
            // Section 4: Full-Word Backspace Deletion & Fresh Word Retyping (25 tests)
            ("test_126_full_bs_muaf_clean", test_126_full_bs_muaf_clean),
            ("test_127_full_bs_swar_clean", test_127_full_bs_swar_clean),
            ("test_128_full_bs_thajat_clean", test_128_full_bs_thajat_clean),
            ("test_129_full_bs_vieetj_clean", test_129_full_bs_vieetj_clean),
            ("test_130_full_bs_over_backspace", test_130_full_bs_over_backspace),
            ("test_131_full_bs_nguoiwf_clean", test_131_full_bs_nguoiwf_clean),
            ("test_132_full_bs_nguyene_clean", test_132_full_bs_nguyene_clean),
            ("test_133_full_bs_dods_clean", test_133_full_bs_dods_clean),
            ("test_134_full_bs_pattern_clean", test_134_full_bs_pattern_clean),
            ("test_135_full_bs_switch_to_sua", test_135_full_bs_switch_to_sua),
            ("test_136_full_bs_tieng_to_chan", test_136_full_bs_tieng_to_chan),
            ("test_137_full_bs_hoa_to_binh", test_137_full_bs_hoa_to_binh),
            ("test_138_full_bs_doc_to_lap", test_138_full_bs_doc_to_lap),
            ("test_139_full_bs_cong_to_nghe", test_139_full_bs_cong_to_nghe),
            ("test_140_full_bs_thong_to_tin", test_140_full_bs_thong_to_tin),
            ("test_141_full_bs_phat_to_trien", test_141_full_bs_phat_to_trien),
            ("test_142_full_bs_vuot_to_bac", test_142_full_bs_vuot_to_bac),
            ("test_143_full_bs_tren_to_nen", test_143_full_bs_tren_to_nen),
            ("test_144_full_bs_tang_to_may", test_144_full_bs_tang_to_may),
            ("test_145_full_bs_tinh_to_mac", test_145_full_bs_tinh_to_mac),
            ("test_146_full_bs_bo_to_go", test_146_full_bs_bo_to_go),
            ("test_147_full_bs_the_to_he", test_147_full_bs_the_to_he),
            ("test_148_full_bs_moi_to_hoat", test_148_full_bs_moi_to_hoat),
            ("test_149_full_bs_dong_to_muot", test_149_full_bs_dong_to_muot),
            ("test_150_full_bs_khong_to_bi", test_150_full_bs_khong_to_bi),
            
            // Section 5: Word-Boundary Backspace Across Spaces (20 tests)
            ("test_151_boundary_space_ha_noi_i", test_151_boundary_space_ha_noi_i),
            ("test_152_boundary_space_ha_noi_is", test_152_boundary_space_ha_noi_is),
            ("test_153_boundary_space_ha_noi_ix", test_153_boundary_space_ha_noi_ix),
            ("test_154_boundary_space_ha_noi_ir", test_154_boundary_space_ha_noi_ir),
            ("test_155_boundary_space_ha_noi_ij", test_155_boundary_space_ha_noi_ij),
            ("test_156_boundary_space_viet_nam_nhat", test_156_boundary_space_viet_nam_nhat),
            ("test_157_boundary_space_hoa_binh_hop", test_157_boundary_space_hoa_binh_hop),
            ("test_158_boundary_space_cong_ly_minh", test_158_boundary_space_cong_ly_minh),
            ("test_159_boundary_space_doc_lap_thien", test_159_boundary_space_doc_lap_thien),
            ("test_160_boundary_space_tu_do_quyen", test_160_boundary_space_tu_do_quyen),
            ("test_161_boundary_space_mua_thu_dong", test_161_boundary_space_mua_thu_dong),
            ("test_162_boundary_space_cay_com_bang", test_162_boundary_space_cay_com_bang),
            ("test_163_boundary_space_pho_xua_phuong", test_163_boundary_space_pho_xua_phuong),
            ("test_164_boundary_space_nha_co_kinh", test_164_boundary_space_nha_co_kinh),
            ("test_165_boundary_space_mai_ngoi_do", test_165_boundary_space_mai_ngoi_do),
            ("test_166_boundary_hard_tab_ha_noi", test_166_boundary_hard_tab_ha_noi),
            ("test_167_boundary_hard_newline_ha_noi", test_167_boundary_hard_newline_ha_noi),
            ("test_168_boundary_hard_escape_ha_noi", test_168_boundary_hard_escape_ha_noi),
            ("test_169_boundary_hard_newline_viet", test_169_boundary_hard_newline_viet),
            ("test_170_boundary_hard_tab_toi", test_170_boundary_hard_tab_toi),
            
            // Section 6: Smart English Auto-Restore & Medials (15 tests)
            ("test_171_english_pattern", test_171_english_pattern),
            ("test_172_english_letter", test_172_english_letter),
            ("test_173_english_button", test_173_english_button),
            ("test_174_english_buffer", test_174_english_buffer),
            ("test_175_english_better", test_175_english_better),
            ("test_176_english_common", test_176_english_common),
            ("test_177_english_matter", test_177_english_matter),
            ("test_178_english_swim", test_178_english_swim),
            ("test_179_english_switch", test_179_english_switch),
            ("test_180_english_swift", test_180_english_swift),
            ("test_181_english_sweet", test_181_english_sweet),
            ("test_182_english_swap", test_182_english_swap),
            ("test_183_english_swing", test_183_english_swing),
            ("test_184_english_string", test_184_english_string),
            ("test_185_english_system", test_185_english_system),
            
            // Section 7: Full Paragraph Real-World Benchmarks (10 tests)
            ("test_186_benchmark_p1_clean_telex", test_186_benchmark_p1_clean_telex),
            ("test_187_benchmark_p1_typos_telex", test_187_benchmark_p1_typos_telex),
            ("test_188_benchmark_p2_clean_telex", test_188_benchmark_p2_clean_telex),
            ("test_189_benchmark_p2_typos_telex", test_189_benchmark_p2_typos_telex),
            ("test_190_benchmark_p1_clean_vni", test_190_benchmark_p1_clean_vni),
            ("test_191_benchmark_p1_typos_vni", test_191_benchmark_p1_typos_vni),
            ("test_192_benchmark_p2_clean_vni", test_192_benchmark_p2_clean_vni),
            ("test_193_benchmark_p2_typos_vni", test_193_benchmark_p2_typos_vni),
            ("test_194_benchmark_combined_clean_telex", test_194_benchmark_combined_clean_telex),
            ("test_195_benchmark_combined_typos_telex", test_195_benchmark_combined_typos_telex),

            // Section 8: Multi-Order Permutations for "mới" & Single-'w' "ươ" (10 tests)
            ("test_196_moi_moiws", test_196_moi_moiws),
            ("test_197_moi_mowis", test_197_moi_mowis),
            ("test_198_moi_mowsi", test_198_moi_mowsi),
            ("test_199_moi_moisw", test_199_moi_moisw),
            ("test_200_moi_mosiw", test_200_moi_mosiw),
            ("test_201_moi_moswi", test_201_moi_moswi),
            ("test_202_sentence_ngay_xa_xua_moiws", test_202_sentence_ngay_xa_xua_moiws),
            ("test_203_single_w_nguwoif", test_203_single_w_nguwoif),
            ("test_204_single_w_truwongf", test_204_single_w_truwongf),
            ("test_205_single_w_dduwocj", test_205_single_w_dduwocj),
        ]
    }
}
