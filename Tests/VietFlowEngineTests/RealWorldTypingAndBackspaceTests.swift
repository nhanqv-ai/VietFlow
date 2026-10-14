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

    // =========================================================================
    // MARK: - Section 9: Scheduled Pattern Batch 1 - "thời / giới / giữ / giữa / trường" Permutations (15 tests)
    // =========================================================================

    func test_206_thoi_all_6_permutations() {
        XCTAssertEqual(apply("thowif thowfi thoiwf thoifw thofiw thofwi"), "thời thời thời thời thời thời")
    }
    func test_207_gioi_all_6_permutations() {
        XCTAssertEqual(apply("giowis giowsi gioiws gioisw giosiw gioswi"), "giới giới giới giới giới giới")
    }
    func test_208_giu_shorthand_and_delayed() {
        XCTAssertEqual(apply("giwx giuwx giuxw"), "giữ giữ giữ")
    }
    func test_209_giua_shorthand_and_delayed() {
        XCTAssertEqual(apply("giwax giuwax giuawx giuxwa"), "giữa giữa giữa giữa")
    }
    func test_210_giuong_shorthand_and_delayed() {
        XCTAssertEqual(apply("giwowfng giwongf giuongwf giuongfw"), "giường giường giường giường")
    }
    func test_211_truong_all_orders() {
        XCTAssertEqual(apply("truwowfng truwongf truongwf truongfw trufowng trwfong"), "trường trường trường trường trường trường")
    }
    func test_212_duoc_all_orders() {
        XCTAssertEqual(apply("dduwowjc dduwocj duowcj dduocwj ddujowc"), "được được được được được")
    }
    func test_213_nuoc_all_orders() {
        XCTAssertEqual(apply("nuwowcs nuwocs nuocws nuocsw nusowc"), "nước nước nước nước nước")
    }
    func test_214_nguoi_all_orders() {
        XCTAssertEqual(apply("nguwowif nguwoif nguoiwf nguoifw ngufowi"), "người người người người người")
    }
    func test_215_line_positions_start_mid_end() {
        XCTAssertEqual(apply("moiws\ngioiws thoiwf\ntrwfong"), "mới\ngiới thời\ntrường")
    }
    func test_216_backspace_mid_gioiws() {
        XCTAssertEqual(apply("gioiws<BS>if"), "giời")
    }
    func test_217_backspace_mid_giwax() {
        XCTAssertEqual(apply("giwax<BS>af"), "giừa")
    }
    func test_218_backspace_across_space_moiws() {
        XCTAssertEqual(apply("tooi moiws <BS><BS>if"), "tôi mời")
    }
    func test_219_quang_delayed_breve() {
        XCTAssertEqual(apply("quawngj quangwj quajwng"), "quặng quặng quặng")
    }
    func test_220_sentence_real_world_batch1() {
        let input = "ngayf xa xuwa khi tooi moiws buwowcs vafo trwfong, giwax bao nguwoif banj mowis"
        let expected = "ngày xa xưa khi tôi mới bước vào trường, giữa bao người bạn mới"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 10: Scheduled Pattern Batch 2 - Circumflex Diphthongs & Triphthongs Permutations (15 tests)
    // =========================================================================

    func test_221_tieng_all_orders() {
        XCTAssertEqual(apply("tieengs tieensg tienges tieseng tiseeng tiensge"), "tiếng tiếng tiếng tiếng tiếng tiếng")
    }
    func test_222_nguyen_all_orders() {
        XCTAssertEqual(apply("nguyeenx nguyeexn nguyenex nguyxeen nguxyeen nguyxene"), "nguyễn nguyễn nguyễn nguyễn nguyễn nguyễn")
    }
    func test_223_chuyen_all_orders() {
        XCTAssertEqual(apply("chuyeenj chuyeejn chuyenje chuyjeen chuyjene"), "chuyện chuyện chuyện chuyện chuyện")
    }
    func test_224_cuoi_all_orders() {
        XCTAssertEqual(apply("cuoois cuoosi cuoios cuoiso cusooi cuosio"), "cuối cuối cuối cuối cuối cuối")
    }
    func test_225_tuoi_all_orders() {
        XCTAssertEqual(apply("tuooir tuoori tuoior tuoiro turooi tuorio"), "tuổi tuổi tuổi tuổi tuổi tuổi")
    }
    func test_226_muon_all_orders() {
        XCTAssertEqual(apply("muoons muoosn muonos muonso musoon muosno"), "muốn muốn muốn muốn muốn muốn")
    }
    func test_227_chieu_all_orders() {
        XCTAssertEqual(apply("chieeuf chieefu chieuef chieufe chiefue"), "chiều chiều chiều chiều chiều")
    }
    func test_228_hieu_all_orders() {
        XCTAssertEqual(apply("hieeur hieeru hieuer hieure hierue"), "hiểu hiểu hiểu hiểu hiểu")
    }
    func test_229_yeu_all_orders() {
        XCTAssertEqual(apply("yeeus yeesu yeues yeuse yesue"), "yếu yếu yếu yếu yếu")
    }
    func test_230_neu_all_orders() {
        XCTAssertEqual(apply("neeus neesu neues neuse nesue"), "nếu nếu nếu nếu nếu")
    }
    func test_231_khuay_all_orders() {
        XCTAssertEqual(apply("khuaays khuaasy khuayas khuaysa khuasya"), "khuấy khuấy khuấy khuấy khuấy")
    }
    func test_232_thuan_all_orders() {
        XCTAssertEqual(apply("thuaanj thuaajn thuanaj thuanja thujaan thuajna"), "thuận thuận thuận thuận thuận thuận")
    }
    func test_233_backspace_mid_circumflex_tienges() {
        XCTAssertEqual(apply("tienges<BS><BS>nf"), "tiền")
    }
    func test_234_backspace_across_space_cuoiso() {
        XCTAssertEqual(apply("ddieerm cuoiso <BS><BS>if"), "điểm cuồi")
    }
    func test_235_sentence_real_world_batch2() {
        let input = "buooir chieufe cuoiso tuaanf, tooi nghe tienges chim host treen canhjf caay"
        let expected = "buổi chiều cuối tuần, tôi nghe tiếng chim hót trên cành cây"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 11: Scheduled Pattern Batch 3 - Breve 'ă/oă' & Dual-W Auto-Complete Permutations (15 tests)
    // =========================================================================

    func test_236_xoan_all_orders() {
        XCTAssertEqual(apply("xoawns xoawsn xoanws xoansw xoasnw xosanw"), "xoắn xoắn xoắn xoắn xoắn xoắn")
    }
    func test_237_hoac_all_orders() {
        XCTAssertEqual(apply("hoawcs hoawsc hoacws hoacsw hoascw hosacw"), "hoắc hoắc hoắc hoắc hoắc hoắc")
    }
    func test_238_ngoat_all_orders() {
        XCTAssertEqual(apply("ngoawtj ngoawjt ngoatwj ngoatjw ngoajtw ngojatw"), "ngoặt ngoặt ngoặt ngoặt ngoặt ngoặt")
    }
    func test_239_thoat_all_orders() {
        XCTAssertEqual(apply("thoawts thoawst thoatws thoatsw thoastw thosatw"), "thoắt thoắt thoắt thoắt thoắt thoắt")
    }
    func test_240_thang_all_orders() {
        XCTAssertEqual(apply("thawngs thawnsg thangws thangsw thasngw thaswng"), "thắng thắng thắng thắng thắng thắng")
    }
    func test_241_bang_all_orders() {
        XCTAssertEqual(apply("bawngf bawngf bangwf bangfw bafngw"), "bằng bằng bằng bằng bằng")
    }
    func test_242_dual_w_nguwoiwf() {
        XCTAssertEqual(apply("nguwoiwf nguwoifw truwongwf truwongfw dduwocwj dduwocjw"), "người người trường trường được được")
    }
    func test_243_dual_w_ruwouwj() {
        XCTAssertEqual(apply("ruwowuj ruwouwj ruwoujw huwowu huwouw"), "rượu rượu rượu hươu hươu")
    }
    func test_244_line_positions_start_mid_end_batch3() {
        XCTAssertEqual(apply("xoanws\nchieufe cuoiso\nnguwoiwf"), "xoắn\nchiều cuối\nngười")
    }
    func test_245_backspace_mid_xoanws() {
        XCTAssertEqual(apply("xoanws<BS>ngf"), "xoằng")
    }
    func test_246_backspace_mid_ngoatwj() {
        XCTAssertEqual(apply("ngoatwj<BS>cs"), "ngoắc")
    }
    func test_247_backspace_across_space_chieufe() {
        XCTAssertEqual(apply("buooir chieufe <BS><BS>us"), "buổi chiếu")
    }
    func test_248_vni_delayed_breve_and_circumflex() {
        XCTAssertEqual(apply("xoa81n xoa1n8 tie61ng tie1ng6", engine: vniEngine), "xoắn xoắn tiếng tiếng")
    }
    func test_249_vni_delayed_horn_and_backspace() {
        XCTAssertEqual(apply("ngu7o72i nguo72i nguoi72<BS>i2", engine: vniEngine), "người người người")
    }
    func test_250_sentence_real_world_batch3() {
        let input = "con dduwowfng ngoatwj qua rwfng thoong xoanws tias duwowis nawsng chieufe"
        let expected = "con đường ngoặt qua rừng thông xoắn tía dưới nắng chiều"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 12: Scheduled Pattern Batch 4 - 'qu-/gi-' Special Syllables, Capitalization & VNI Permutations (15 tests)
    // =========================================================================

    func test_251_quoc_all_orders() {
        XCTAssertEqual(apply("quoocs quoosc quocos quocso qusooc quosco"), "quốc quốc quốc quốc quốc quốc")
    }
    func test_252_quyen_all_orders() {
        XCTAssertEqual(apply("quyeens quyeesn quyenes quyense quyseen quyesne"), "quyến quyến quyến quyến quyến quyến")
    }
    func test_253_quyet_all_orders() {
        XCTAssertEqual(apply("quyeets quyeest quyetes quyetse quyseet quyeste"), "quyết quyết quyết quyết quyết quyết")
    }
    func test_254_quan_circumflex_all_orders() {
        XCTAssertEqual(apply("quaanx quaaxn quanax quanxa quxaan quaxna"), "quẫn quẫn quẫn quẫn quẫn quẫn")
    }
    func test_255_quay_circumflex_all_orders() {
        XCTAssertEqual(apply("quaayr quaary quayar quayra quray<BS><BS>aayr"), "quẩy quẩy quẩy quẩy quẩy")
    }
    func test_256_gieng_all_orders() {
        XCTAssertEqual(apply("gieengs gieensg gienges gieseng giseeng"), "giếng giếng giếng giếng giếng")
    }
    func test_257_gieu_all_orders() {
        XCTAssertEqual(apply("gieeux gieexu gieuex gieuxe giexue"), "giễu giễu giễu giễu giễu")
    }
    func test_258_giay_all_orders() {
        XCTAssertEqual(apply("giaays giaasy giayas giaysa giasya"), "giấy giấy giấy giấy giấy")
    }
    func test_259_capitalized_free_order_permutations() {
        XCTAssertEqual(apply("Moiws Mowis Nguoiwf Nguwoif Trwfong Swar Dods"), "Mới Mới Người Người Trường Sửa Đó")
    }
    func test_260_uppercase_free_order_permutations() {
        XCTAssertEqual(apply("MOIWS MOWIS NGUOIWF NGUWOIF TRWFONG SWAR DODS"), "MỚI MỚI NGƯỜI NGƯỜI TRƯỜNG SỬA ĐÓ")
    }
    func test_261_vni_moi_all_6_permutations() {
        XCTAssertEqual(apply("mo7i1 mo71i moi71 moi17 mo1i7 mo17i", engine: vniEngine), "mới mới mới mới mới mới")
    }
    func test_262_vni_truong_all_orders() {
        XCTAssertEqual(apply("tru7o72ng truo72ng truong72 tru2o7ng", engine: vniEngine), "trường trường trường trường")
    }
    func test_263_backspace_capitalized_and_uppercase() {
        XCTAssertEqual(apply("Nguoiwf<BS>if MOISW<BS>IF"), "Người MỜI")
    }
    func test_264_backspace_across_space_quyetse() {
        XCTAssertEqual(apply("kiene quyetse <BS><BS>nf"), "kiên quyền")
    }
    func test_265_sentence_real_world_batch4() {
        let input = "Vafo buooir sangs Moiws, Nguwoif daan Quocso Gia lufng sucj<BS><BS>ucj timf kiemes giaays towf"
        let expected = "Vào buổi sáng Mới, Người dân Quốc Gia lùng sục tìm kiếm giấy tờ"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 13: Scheduled Pattern Batch 5 - Shorthand C+w+o+i/c, Open Diphthongs/Triphthongs & Tone Override/Clear (15 tests)
    // =========================================================================

    func test_266_shorthand_cw_oi_muoi_cuoi_luoi_suoi() {
        XCTAssertEqual(apply("mwoif mwfoi cwois cwsoi lwois lwsoi swoir swroi"), "mười mười cưới cưới lưới lưới sưởi sưởi")
    }
    func test_267_shorthand_cw_oc_buoc_nuoc_duoc_thuoc() {
        XCTAssertEqual(apply("bwocs bwsoc nwocs nwsoc ddwocj ddwjoc thwocs thwsoc"), "bước bước nước nước được được thước thước")
    }
    func test_268_shorthand_cw_ong_duong_luong_tuong_huong() {
        XCTAssertEqual(apply("ddwongf ddwfong lwongf lwfong twongr twrong hwongs hwsong"), "đường đường lường lường tưởng tưởng hướng hướng")
    }
    func test_269_open_triphthong_ngoai_all_orders() {
        XCTAssertEqual(apply("ngoaif ngoafi ngofai xoays xosay"), "ngoài ngoài ngoài xoáy xoáy")
    }
    func test_270_open_triphthong_khuyu_ngoeo_all_orders() {
        XCTAssertEqual(apply("khuyur khuyru khuryu ngoeoj ngoejo ngojeo"), "khuỷu khuỷu khuỷu ngoẹo ngoẹo ngoẹo")
    }
    func test_271_open_diphthong_khoe_thuy_hoa_all_orders() {
        XCTAssertEqual(apply("khoer khore thuys thusy hoaf hofa"), "khỏe khỏe thúy thúy hòa hòa")
    }
    func test_272_tone_override_on_free_order_moiws() {
        XCTAssertEqual(apply("moiwsf moiswr mosiwx moswij"), "mời mởi mỡi mợi")
    }
    func test_273_tone_clear_z_on_free_order_words() {
        XCTAssertEqual(apply("moiwsz nguoiwfz tiengesz xoanwsz"), "mơi ngươi tiêng xoăn")
    }
    func test_274_vni_tone_override_and_clear_0() {
        XCTAssertEqual(apply("moi712 moi710 tie61ng2 tie61ng0", engine: vniEngine), "mời mơi tiềng tiêng")
    }
    func test_275_backspace_after_tone_override_moiwsf() {
        XCTAssertEqual(apply("moiwsf<BS>is"), "mới")
    }
    func test_276_backspace_after_shorthand_cw_oi() {
        XCTAssertEqual(apply("mwoif<BS>is"), "mưới")
    }
    func test_277_backspace_multi_word_across_two_spaces() {
        XCTAssertEqual(apply("tooi moiws ddi <BS><BS><BS><BS><BS>if veef"), "tôi mời về")
    }
    func test_278_line_positions_start_mid_end_batch5() {
        XCTAssertEqual(apply("mwoif\nbwocs ddwongf\nngoaif"), "mười\nbước đường\nngoài")
    }
    func test_279_double_key_undo_then_backspace_and_retype() {
        XCTAssertEqual(apply("swar<BS><BS>wimming"), "swimming")
    }
    func test_280_sentence_real_world_batch5() {
        let input = "mwoif nawm trwocs, tooi bwocs ddi treen ddwongf ngoaif phoos vaf nhows laij nhwngx kyr nieemj"
        let expected = "mười năm trước, tôi bước đi trên đường ngoài phố và nhớ lại những kỷ niệm"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 14: Scheduled Pattern Batch 6 - Palatal Codas '-ch/-nh', Delayed 'd->đ' & Traditional Tone Style (15 tests)
    // =========================================================================

    func test_281_huynh_quynh_all_orders() {
        XCTAssertEqual(apply("huynhf huyfnh hufynh huynfh quynhf quyfnh quynfh"), "huỳnh huỳnh huỳnh huỳnh quỳnh quỳnh quỳnh")
    }
    func test_282_huych_all_orders() {
        XCTAssertEqual(apply("huychs huysch husych huycsh"), "huých huých huých huých")
    }
    func test_283_benh_lenh_all_orders() {
        XCTAssertEqual(apply("beenhj beenjh benhej benhje bejenh benjhe leenhj lenhje"), "bệnh bệnh bệnh bệnh bệnh bệnh lệnh lệnh")
    }
    func test_284_kech_lech_all_orders() {
        XCTAssertEqual(apply("keechs keecsh keches kechse kesech kecshe leechj lechje"), "kếch kếch kếch kếch kếch kếch lệch lệch")
    }
    func test_285_lich_manh_all_orders() {
        XCTAssertEqual(apply("lichj lijch licjh manhj majnh manjh"), "lịch lịch lịch mạnh mạnh mạnh")
    }
    func test_286_delayed_d_duong_all_orders() {
        XCTAssertEqual(apply("dduwowfng duwowfngd duwongfd duongwfd duongdfw duwfongd"), "đường đường đường đường đường đường")
    }
    func test_287_delayed_d_dong_dinh_all_orders() {
        XCTAssertEqual(apply("ddoongs doongsd dongods dongosd dosongd ddinhs dinhsd disnhd"), "đống đống đống đống đống đính đính đính")
    }
    func test_288_delayed_d_duoc_all_orders() {
        XCTAssertEqual(apply("dduwowjc duwowjcd duwocjd duocwjd duocjdw"), "được được được được được")
    }
    func test_289_traditional_tone_oa_oe_uy_all_orders() {
        let tradEngine = makeEngine(inputMethod: .telex, tonePlacement: .traditional)
        XCTAssertEqual(apply("hoaf hofa khoer khore thuys thusy", engine: tradEngine), "hoà hoà khoẻ khoẻ thuý thuý")
    }
    func test_290_traditional_tone_backspace_and_edit() {
        let tradEngine = makeEngine(inputMethod: .telex, tonePlacement: .traditional)
        XCTAssertEqual(apply("hoaf<BS>as thuys<BS>yf", engine: tradEngine), "hoá thuỳ")
    }
    func test_291_backspace_mid_palatal_benhje() {
        XCTAssertEqual(apply("benhje<BS><BS>chs"), "bếch")
    }
    func test_292_backspace_mid_delayed_d_duongwfd() {
        XCTAssertEqual(apply("duongwfd<BS><BS>if"), "đười")
    }
    func test_293_backspace_across_space_huynhf() {
        XCTAssertEqual(apply("hoa huynhf <BS><BS><BS>sch"), "hoa huých")
    }
    func test_294_line_positions_start_mid_end_batch6() {
        XCTAssertEqual(apply("beenhj\nhuynhf duongwfd\nkeechs"), "bệnh\nhuỳnh đường\nkếch")
    }
    func test_295_sentence_real_world_batch6() {
        let input = "anh Huynhf ddi treen duongwfd leechj veef phias benhje vieenj ddeer khams sucws khoer"
        let expected = "anh Huỳnh đi trên đường lệch về phía bệnh viện để khám sức khỏe"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 15: Scheduled Pattern Batch 7 - Compound Splitting, Punctuation Boundaries & 'ươ+m/p/t' Permutations (15 tests)
    // =========================================================================

    func test_296_buom_all_orders() {
        XCTAssertEqual(apply("buwowms buwoms buomws buomsw busowm bwoms"), "bướm bướm bướm bướm bướm bướm")
    }
    func test_297_cuop_all_orders() {
        XCTAssertEqual(apply("cuwowps cuwops cuopws cuopsw cusowp cwops"), "cướp cướp cướp cướp cướp cướp")
    }
    func test_298_muot_all_orders() {
        XCTAssertEqual(apply("muwowtj muwotj muotwj muotjw mujowt mwotj"), "mượt mượt mượt mượt mượt mượt")
    }
    func test_299_luot_all_orders() {
        XCTAssertEqual(apply("luwowts luwots luotws luotsw lusowt lwots"), "lướt lướt lướt lướt lướt lướt")
    }
    func test_300_nghieng_all_orders() {
        XCTAssertEqual(apply("nghieengf nghieefng nghiengfe nghiefeng nghifeng"), "nghiềng nghiềng nghiềng nghiềng nghiềng")
    }
    func test_301_compound_syllable_splitting() {
        XCTAssertEqual(apply("hairphofng vieetjnam thafnhphoos"), "hảiphòng việtnam thànhphố")
    }
    func test_302_punctuation_boundaries_brackets_and_quotes() {
        XCTAssertEqual(apply("(moiws) [nguoiwf] \"swar\" 'trwfong' {quocso}"), "(mới) [người] \"sửa\" 'trường' {quốc}")
    }
    func test_303_punctuation_boundaries_slash_hyphen_colon() {
        XCTAssertEqual(apply("ngayf-thangs-nawm sangs/trwa/chieufe/toois: moiws!"), "ngày-tháng-năm sáng/trưa/chiều/tối: mới!")
    }
    func test_304_multiline_tabs_and_newlines_free_order() {
        XCTAssertEqual(apply("moiws\tnguoiwf\ntrwfong\tchieufe\nxoanws"), "mới\tngười\ntrường\tchiều\nxoắn")
    }
    func test_305_backspace_mid_buomws() {
        XCTAssertEqual(apply("buomws<BS>ir"), "bưởi")
    }
    func test_306_backspace_mid_cuopws() {
        XCTAssertEqual(apply("cuopws<BS>is"), "cưới")
    }
    func test_307_backspace_mid_muotwj() {
        XCTAssertEqual(apply("muotwj<BS>nf"), "mườn")
    }
    func test_308_backspace_across_space_nghiengfe() {
        XCTAssertEqual(apply("maij nghiengfe <BS><BS><BS>us"), "mại nghiếu")
    }
    func test_309_vni_buom_cuop_muot_all_orders() {
        XCTAssertEqual(apply("bu7o7m1 buo7m1 buom71 cuo7p1 muo7t5", engine: vniEngine), "bướm bướm bướm cướp mượt")
    }
    func test_310_sentence_real_world_batch7() {
        let input = "ddafo buomws bay luwowts nhesj treen suownf ddooif muotwj maf duwowis nawsng mai"
        let expected = "đào bướm bay lướt nhẹ trên sườn đồi mượt mà dưới nắng mai"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 16: Scheduled Pattern Batch 8 - 'ưu' & 'ưi' Permutations, 'quơ/quở' & Backspace (15 tests)
    // =========================================================================

    func test_311_cuu_acute_all_orders() {
        XCTAssertEqual(apply("cuwus cuuws cuusw cuswu cusuw cwus cwsu"), "cứu cứu cứu cứu cứu cứu cứu")
    }
    func test_312_cuu_grave_all_orders() {
        XCTAssertEqual(apply("cuwuf cuuwf cuufw cufwu cufuw cwuf cwfu"), "cừu cừu cừu cừu cừu cừu cừu")
    }
    func test_313_luu_huu_buu_suu_all_orders() {
        XCTAssertEqual(apply("luwu luuw lwu huwu huuw buwu buuw suwu suuw"), "lưu lưu lưu hưu hưu bưu bưu sưu sưu")
    }
    func test_314_truu_tuu_huu_tones_all_orders() {
        XCTAssertEqual(apply("truwuf truuwf truufw trwuf tuwur tuuwr tuurw huwux huuwx"), "trừu trừu trừu trừu tửu tửu tửu hữu hữu")
    }
    func test_315_gui_all_orders() {
        XCTAssertEqual(apply("guwir guwri guiwr guirw gurwi guriw gwir gwri"), "gửi gửi gửi gửi gửi gửi gửi gửi")
    }
    func test_316_ngui_chui_cui_all_orders() {
        XCTAssertEqual(apply("nguwir nguwir nguiwr nguirw ngwir chuwir chuiwr chwir cuwir cuiwr cwir"), "ngửi ngửi ngửi ngửi ngửi chửi chửi chửi cửi cửi cửi")
    }
    func test_317_quo_quor_all_orders() {
        XCTAssertEqual(apply("quow quowr quorw qurow"), "quơ quở quở quở")
    }
    func test_318_xosawn_hosawc_ngojawt_early_tone_before_breve() {
        XCTAssertEqual(apply("xosawn hosawc ngojawt thosawt"), "xoắn hoắc ngoặt thoắt")
    }
    func test_319_vni_cuu_gui_all_orders() {
        XCTAssertEqual(apply("cu7u1 cuu71 cu1u7 gu7i3 gui73 gu3i7", engine: vniEngine), "cứu cứu cứu gửi gửi gửi")
    }
    func test_320_backspace_mid_cuuws() {
        XCTAssertEqual(apply("cuuws<BS>uf"), "cừu")
    }
    func test_321_backspace_mid_guiwr() {
        XCTAssertEqual(apply("guiwr<BS>ax"), "gữa")
    }
    func test_322_backspace_across_space_cuuws() {
        XCTAssertEqual(apply("nghiene cuuws <BS><BS>uf"), "nghiên cừu")
    }
    func test_323_line_positions_start_mid_end_batch8() {
        XCTAssertEqual(apply("cuuws\nguiwr luuw\ntruuwf"), "cứu\ngửi lưu\ntrừu")
    }
    func test_324_capitalized_and_uppercase_uu_ui() {
        XCTAssertEqual(apply("Cuuws CUUWS Guiwr GUIWR Luuw LUUW"), "Cứu CỨU Gửi GỬI Lưu LƯU")
    }
    func test_325_sentence_real_world_batch8() {
        let input = "nhaan vieen buuw ddieenj guwir buuw phamar cuuws trojw ddeens vufng lux"
        let expected = "nhân viên bưu điện gửi bưu phẩm cứu trợ đến vùng lũ"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 17: Scheduled Pattern Batch 9 - Closed-Syllable Monophthongs ('ă/â/ê/ô/ơ/ư') & SimpleTelex Free-Order (15 tests)
    // =========================================================================

    func test_326_breve_a_closed_codas_all_orders() {
        XCTAssertEqual(apply("tawms tamws tamsw tasmw lawps lapws lapsw mawcs macws macsw"), "tắm tắm tắm tắm lắp lắp lắp mắc mắc mắc")
    }
    func test_327_breve_a_dot_and_delayed_d_all_orders() {
        XCTAssertEqual(apply("gawpj gapwj gapjw gajpw ddawtj ddatwj ddatjw datwjd"), "gặp gặp gặp gặp đặt đặt đặt đặt")
    }
    func test_328_circumflex_a_closed_codas_all_orders() {
        XCTAssertEqual(apply("taams tamas tamsa tasma caans canas cansa casna thaats thatas thatsa"), "tấm tấm tấm tấm cấn cấn cấn cấn thất thất thất")
    }
    func test_329_circumflex_e_closed_codas_all_orders() {
        XCTAssertEqual(apply("ddeems ddemes ddemse demesd beens benes bense heets hetes hetse"), "đếm đếm đếm đếm bến bến bến hết hết hết")
    }
    func test_330_circumflex_o_closed_codas_all_orders() {
        XCTAssertEqual(apply("cooms comos comso cosmo toons tonos tonso tosno toots totos totso"), "cốm cốm cốm cốm tốn tốn tốn tốn tốt tốt tốt")
    }
    func test_331_horn_o_closed_codas_all_orders() {
        XCTAssertEqual(apply("sowms somws somsw sosmw lowns lonws lonsw losnw bowts botws botsw bostw"), "sớm sớm sớm sớm lớn lớn lớn lớn bớt bớt bớt bớt")
    }
    func test_332_horn_u_closed_codas_all_orders() {
        XCTAssertEqual(apply("huwngs hungws hungsw husngw hwngs muwcs mucws mucsw mwcs dduwts ddutws ddutsw"), "hứng hứng hứng hứng hứng mức mức mức mức đứt đứt đứt")
    }
    func test_333_simple_telex_free_order_moiws_nguoiwf_truongwf() {
        let simpleEngine = makeEngine(inputMethod: .simpleTelex, tonePlacement: .modern)
        XCTAssertEqual(apply("moiws mowis mowsi nguoiwf nguwoif truwowfng truongwf", engine: simpleEngine), "mới mới mới người người trường trường")
    }
    func test_334_simple_telex_free_order_circumflex_and_breve() {
        let simpleEngine = makeEngine(inputMethod: .simpleTelex, tonePlacement: .modern)
        XCTAssertEqual(apply("tienges nguyenex xoanws cuuws dods", engine: simpleEngine), "tiếng nguyễn xoắn cứu đó")
    }
    func test_335_simple_telex_backspace_mid_and_across_space() {
        let simpleEngine = makeEngine(inputMethod: .simpleTelex, tonePlacement: .modern)
        XCTAssertEqual(apply("tooi moiws <BS><BS>if", engine: simpleEngine), "tôi mời")
    }
    func test_336_backspace_mid_closed_monophthong_tasmw() {
        XCTAssertEqual(apply("tasmw<BS>ngf"), "tằng")
    }
    func test_337_backspace_mid_closed_monophthong_cosmo() {
        XCTAssertEqual(apply("cosmo<BS>ngf"), "cồng")
    }
    func test_338_backspace_across_space_demesd() {
        XCTAssertEqual(apply("ban demesd <BS><BS>mf"), "ban đềm")
    }
    func test_339_line_positions_start_mid_end_batch9() {
        XCTAssertEqual(apply("tasmw\ncosmo sosmw\nhusngw"), "tắm\ncốm sớm\nhứng")
    }
    func test_340_sentence_real_world_batch9() {
        let input = "sowms nay trowif lowns nawsng, tooi ddemes twfng buwowcs chaan treen con dduwowfng rwfng"
        let expected = "sớm nay trời lớn nắng, tôi đếm từng bước chân trên con đường rừng"
        XCTAssertEqual(apply(input), expected)
    }

    // =========================================================================
    // MARK: - Section 18: Scheduled Pattern Batch 10 - 'trời/đời/khởi', 'rượu/khướu/bướu' & Code-Switching + Backspace (15 tests)
    // =========================================================================

    func test_341_troi_all_6_permutations() {
        XCTAssertEqual(apply("trowif trowfi troiwf troifw trofiw trofwi"), "trời trời trời trời trời trời")
    }
    func test_342_doi_all_permutations_with_delayed_d() {
        XCTAssertEqual(apply("ddowif ddowfi ddoiwf ddoifw ddofiw ddofwi doifwd doiwfd"), "đời đời đời đời đời đời đời đời")
    }
    func test_343_khoi_loi_ngoi_all_orders() {
        XCTAssertEqual(apply("khowir khoiwr khoirw khorwi khoriw lowij loiwj loijw ngowij ngoiwj"), "khởi khởi khởi khởi khởi lợi lợi lợi ngợi ngợi")
    }
    func test_344_ruou_all_orders() {
        XCTAssertEqual(apply("ruwowuj ruwouwj ruwoujw ruouwj ruoujw rujowu rwouj"), "rượu rượu rượu rượu rượu rượu rượu")
    }
    func test_345_khuou_buou_all_orders() {
        XCTAssertEqual(apply("khuwowus khuwous khuouws khuousw khusowu khwous buwowus buwous buouws buousw bwous"), "khướu khướu khướu khướu khướu khướu bướu bướu bướu bướu bướu")
    }
    func test_346_code_switching_vietnamese_and_english_keywords() {
        XCTAssertEqual(apply("tooi code swift vaf fix bug pattern moiws treen github"), "tôi code swift và fix bug pattern mới trên github")
    }
    func test_347_code_switching_with_backspace_and_edit() {
        XCTAssertEqual(apply("tooi code swift<BS><BS><BS><BS>war looxi trong terminal"), "tôi code sửa lỗi trong terminal")
    }
    func test_348_backspace_mid_ruouwj() {
        XCTAssertEqual(apply("ruouwj<BS>is"), "rưới")
    }
    func test_349_backspace_mid_khuouws() {
        XCTAssertEqual(apply("khuouws<BS>ir"), "khưởi")
    }
    func test_350_backspace_across_space_troiwf() {
        XCTAssertEqual(apply("ngayf troiwf <BS><BS>is"), "ngày trới")
    }
    func test_351_line_positions_start_mid_end_batch10() {
        XCTAssertEqual(apply("troiwf\nruouwj khuouws\nddoiwf"), "trời\nrượu khướu\nđời")
    }
    func test_352_vni_troi_doi_ruou_all_orders() {
        XCTAssertEqual(apply("tro7i2 troi72 tro2i7 d9o7i2 doi972 ru7o7u5 ruou75", engine: vniEngine), "trời trời trời đời đời rượu rượu")
    }
    func test_353_full_line_delete_and_retype_across_multiple_words() {
        XCTAssertEqual(apply("haif nooij <BS><BS><BS><BS><BS><BS><BS>af nooij muaf thu"), "hà nội mùa thu")
    }
    func test_354_multi_sentence_backspace_stress_test() {
        let input = "ngayf xa xwa<BS>a khi tooi moiws<BS>is vafo trwfong, tooi ddax gapwj nhwngx nguoiwf banj thajat tuyeetj vowif."
        let expected = "ngày xa xưa khi tôi mới vào trường, tôi đã gặp những người bạn thật tuyệt vời."
        XCTAssertEqual(apply(input), expected)
    }
    func test_355_sentence_real_world_batch10() {
        let input = "duwowis baauf troiwf muas<BS>af thu, tienges chim khuouws hots vang giwax rwfng caay xanh mwowts"
        let expected = "dưới bầu trời mùa thu, tiếng chim khướu hót vang giữa rừng cây xanh mướt"
        XCTAssertEqual(apply(input), expected)
    }
    
    // MARK: - Test Registry (355 Tests)
    
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

            // Section 9: Scheduled Pattern Batch 1 - "thời / giới / giữ / giữa / trường" Permutations (15 tests)
            ("test_206_thoi_all_6_permutations", test_206_thoi_all_6_permutations),
            ("test_207_gioi_all_6_permutations", test_207_gioi_all_6_permutations),
            ("test_208_giu_shorthand_and_delayed", test_208_giu_shorthand_and_delayed),
            ("test_209_giua_shorthand_and_delayed", test_209_giua_shorthand_and_delayed),
            ("test_210_giuong_shorthand_and_delayed", test_210_giuong_shorthand_and_delayed),
            ("test_211_truong_all_orders", test_211_truong_all_orders),
            ("test_212_duoc_all_orders", test_212_duoc_all_orders),
            ("test_213_nuoc_all_orders", test_213_nuoc_all_orders),
            ("test_214_nguoi_all_orders", test_214_nguoi_all_orders),
            ("test_215_line_positions_start_mid_end", test_215_line_positions_start_mid_end),
            ("test_216_backspace_mid_gioiws", test_216_backspace_mid_gioiws),
            ("test_217_backspace_mid_giwax", test_217_backspace_mid_giwax),
            ("test_218_backspace_across_space_moiws", test_218_backspace_across_space_moiws),
            ("test_219_quang_delayed_breve", test_219_quang_delayed_breve),
            ("test_220_sentence_real_world_batch1", test_220_sentence_real_world_batch1),

            // Section 10: Scheduled Pattern Batch 2 - Circumflex Diphthongs & Triphthongs Permutations (15 tests)
            ("test_221_tieng_all_orders", test_221_tieng_all_orders),
            ("test_222_nguyen_all_orders", test_222_nguyen_all_orders),
            ("test_223_chuyen_all_orders", test_223_chuyen_all_orders),
            ("test_224_cuoi_all_orders", test_224_cuoi_all_orders),
            ("test_225_tuoi_all_orders", test_225_tuoi_all_orders),
            ("test_226_muon_all_orders", test_226_muon_all_orders),
            ("test_227_chieu_all_orders", test_227_chieu_all_orders),
            ("test_228_hieu_all_orders", test_228_hieu_all_orders),
            ("test_229_yeu_all_orders", test_229_yeu_all_orders),
            ("test_230_neu_all_orders", test_230_neu_all_orders),
            ("test_231_khuay_all_orders", test_231_khuay_all_orders),
            ("test_232_thuan_all_orders", test_232_thuan_all_orders),
            ("test_233_backspace_mid_circumflex_tienges", test_233_backspace_mid_circumflex_tienges),
            ("test_234_backspace_across_space_cuoiso", test_234_backspace_across_space_cuoiso),
            ("test_235_sentence_real_world_batch2", test_235_sentence_real_world_batch2),

            // Section 11: Scheduled Pattern Batch 3 - Breve 'ă/oă' & Dual-W Auto-Complete Permutations (15 tests)
            ("test_236_xoan_all_orders", test_236_xoan_all_orders),
            ("test_237_hoac_all_orders", test_237_hoac_all_orders),
            ("test_238_ngoat_all_orders", test_238_ngoat_all_orders),
            ("test_239_thoat_all_orders", test_239_thoat_all_orders),
            ("test_240_thang_all_orders", test_240_thang_all_orders),
            ("test_241_bang_all_orders", test_241_bang_all_orders),
            ("test_242_dual_w_nguwoiwf", test_242_dual_w_nguwoiwf),
            ("test_243_dual_w_ruwouwj", test_243_dual_w_ruwouwj),
            ("test_244_line_positions_start_mid_end_batch3", test_244_line_positions_start_mid_end_batch3),
            ("test_245_backspace_mid_xoanws", test_245_backspace_mid_xoanws),
            ("test_246_backspace_mid_ngoatwj", test_246_backspace_mid_ngoatwj),
            ("test_247_backspace_across_space_chieufe", test_247_backspace_across_space_chieufe),
            ("test_248_vni_delayed_breve_and_circumflex", test_248_vni_delayed_breve_and_circumflex),
            ("test_249_vni_delayed_horn_and_backspace", test_249_vni_delayed_horn_and_backspace),
            ("test_250_sentence_real_world_batch3", test_250_sentence_real_world_batch3),

            // Section 12: Scheduled Pattern Batch 4 - 'qu-/gi-' Special Syllables, Capitalization & VNI Permutations (15 tests)
            ("test_251_quoc_all_orders", test_251_quoc_all_orders),
            ("test_252_quyen_all_orders", test_252_quyen_all_orders),
            ("test_253_quyet_all_orders", test_253_quyet_all_orders),
            ("test_254_quan_circumflex_all_orders", test_254_quan_circumflex_all_orders),
            ("test_255_quay_circumflex_all_orders", test_255_quay_circumflex_all_orders),
            ("test_256_gieng_all_orders", test_256_gieng_all_orders),
            ("test_257_gieu_all_orders", test_257_gieu_all_orders),
            ("test_258_giay_all_orders", test_258_giay_all_orders),
            ("test_259_capitalized_free_order_permutations", test_259_capitalized_free_order_permutations),
            ("test_260_uppercase_free_order_permutations", test_260_uppercase_free_order_permutations),
            ("test_261_vni_moi_all_6_permutations", test_261_vni_moi_all_6_permutations),
            ("test_262_vni_truong_all_orders", test_262_vni_truong_all_orders),
            ("test_263_backspace_capitalized_and_uppercase", test_263_backspace_capitalized_and_uppercase),
            ("test_264_backspace_across_space_quyetse", test_264_backspace_across_space_quyetse),
            ("test_265_sentence_real_world_batch4", test_265_sentence_real_world_batch4),

            // Section 13: Scheduled Pattern Batch 5 - Shorthand C+w+o+i/c, Open Diphthongs/Triphthongs & Tone Override/Clear (15 tests)
            ("test_266_shorthand_cw_oi_muoi_cuoi_luoi_suoi", test_266_shorthand_cw_oi_muoi_cuoi_luoi_suoi),
            ("test_267_shorthand_cw_oc_buoc_nuoc_duoc_thuoc", test_267_shorthand_cw_oc_buoc_nuoc_duoc_thuoc),
            ("test_268_shorthand_cw_ong_duong_luong_tuong_huong", test_268_shorthand_cw_ong_duong_luong_tuong_huong),
            ("test_269_open_triphthong_ngoai_all_orders", test_269_open_triphthong_ngoai_all_orders),
            ("test_270_open_triphthong_khuyu_ngoeo_all_orders", test_270_open_triphthong_khuyu_ngoeo_all_orders),
            ("test_271_open_diphthong_khoe_thuy_hoa_all_orders", test_271_open_diphthong_khoe_thuy_hoa_all_orders),
            ("test_272_tone_override_on_free_order_moiws", test_272_tone_override_on_free_order_moiws),
            ("test_273_tone_clear_z_on_free_order_words", test_273_tone_clear_z_on_free_order_words),
            ("test_274_vni_tone_override_and_clear_0", test_274_vni_tone_override_and_clear_0),
            ("test_275_backspace_after_tone_override_moiwsf", test_275_backspace_after_tone_override_moiwsf),
            ("test_276_backspace_after_shorthand_cw_oi", test_276_backspace_after_shorthand_cw_oi),
            ("test_277_backspace_multi_word_across_two_spaces", test_277_backspace_multi_word_across_two_spaces),
            ("test_278_line_positions_start_mid_end_batch5", test_278_line_positions_start_mid_end_batch5),
            ("test_279_double_key_undo_then_backspace_and_retype", test_279_double_key_undo_then_backspace_and_retype),
            ("test_280_sentence_real_world_batch5", test_280_sentence_real_world_batch5),

            // Section 14: Scheduled Pattern Batch 6 - Palatal Codas '-ch/-nh', Delayed 'd->đ' & Traditional Tone Style (15 tests)
            ("test_281_huynh_quynh_all_orders", test_281_huynh_quynh_all_orders),
            ("test_282_huych_all_orders", test_282_huych_all_orders),
            ("test_283_benh_lenh_all_orders", test_283_benh_lenh_all_orders),
            ("test_284_kech_lech_all_orders", test_284_kech_lech_all_orders),
            ("test_285_lich_manh_all_orders", test_285_lich_manh_all_orders),
            ("test_286_delayed_d_duong_all_orders", test_286_delayed_d_duong_all_orders),
            ("test_287_delayed_d_dong_dinh_all_orders", test_287_delayed_d_dong_dinh_all_orders),
            ("test_288_delayed_d_duoc_all_orders", test_288_delayed_d_duoc_all_orders),
            ("test_289_traditional_tone_oa_oe_uy_all_orders", test_289_traditional_tone_oa_oe_uy_all_orders),
            ("test_290_traditional_tone_backspace_and_edit", test_290_traditional_tone_backspace_and_edit),
            ("test_291_backspace_mid_palatal_benhje", test_291_backspace_mid_palatal_benhje),
            ("test_292_backspace_mid_delayed_d_duongwfd", test_292_backspace_mid_delayed_d_duongwfd),
            ("test_293_backspace_across_space_huynhf", test_293_backspace_across_space_huynhf),
            ("test_294_line_positions_start_mid_end_batch6", test_294_line_positions_start_mid_end_batch6),
            ("test_295_sentence_real_world_batch6", test_295_sentence_real_world_batch6),

            // Section 15: Scheduled Pattern Batch 7 - Compound Splitting, Punctuation Boundaries & 'ươ+m/p/t' Permutations (15 tests)
            ("test_296_buom_all_orders", test_296_buom_all_orders),
            ("test_297_cuop_all_orders", test_297_cuop_all_orders),
            ("test_298_muot_all_orders", test_298_muot_all_orders),
            ("test_299_luot_all_orders", test_299_luot_all_orders),
            ("test_300_nghieng_all_orders", test_300_nghieng_all_orders),
            ("test_301_compound_syllable_splitting", test_301_compound_syllable_splitting),
            ("test_302_punctuation_boundaries_brackets_and_quotes", test_302_punctuation_boundaries_brackets_and_quotes),
            ("test_303_punctuation_boundaries_slash_hyphen_colon", test_303_punctuation_boundaries_slash_hyphen_colon),
            ("test_304_multiline_tabs_and_newlines_free_order", test_304_multiline_tabs_and_newlines_free_order),
            ("test_305_backspace_mid_buomws", test_305_backspace_mid_buomws),
            ("test_306_backspace_mid_cuopws", test_306_backspace_mid_cuopws),
            ("test_307_backspace_mid_muotwj", test_307_backspace_mid_muotwj),
            ("test_308_backspace_across_space_nghiengfe", test_308_backspace_across_space_nghiengfe),
            ("test_309_vni_buom_cuop_muot_all_orders", test_309_vni_buom_cuop_muot_all_orders),
            ("test_310_sentence_real_world_batch7", test_310_sentence_real_world_batch7),

            // Section 16: Scheduled Pattern Batch 8 - 'ưu' & 'ưi' Permutations, 'quơ/quở' & Backspace (15 tests)
            ("test_311_cuu_acute_all_orders", test_311_cuu_acute_all_orders),
            ("test_312_cuu_grave_all_orders", test_312_cuu_grave_all_orders),
            ("test_313_luu_huu_buu_suu_all_orders", test_313_luu_huu_buu_suu_all_orders),
            ("test_314_truu_tuu_huu_tones_all_orders", test_314_truu_tuu_huu_tones_all_orders),
            ("test_315_gui_all_orders", test_315_gui_all_orders),
            ("test_316_ngui_chui_cui_all_orders", test_316_ngui_chui_cui_all_orders),
            ("test_317_quo_quor_all_orders", test_317_quo_quor_all_orders),
            ("test_318_xosawn_hosawc_ngojawt_early_tone_before_breve", test_318_xosawn_hosawc_ngojawt_early_tone_before_breve),
            ("test_319_vni_cuu_gui_all_orders", test_319_vni_cuu_gui_all_orders),
            ("test_320_backspace_mid_cuuws", test_320_backspace_mid_cuuws),
            ("test_321_backspace_mid_guiwr", test_321_backspace_mid_guiwr),
            ("test_322_backspace_across_space_cuuws", test_322_backspace_across_space_cuuws),
            ("test_323_line_positions_start_mid_end_batch8", test_323_line_positions_start_mid_end_batch8),
            ("test_324_capitalized_and_uppercase_uu_ui", test_324_capitalized_and_uppercase_uu_ui),
            ("test_325_sentence_real_world_batch8", test_325_sentence_real_world_batch8),

            // Section 17: Scheduled Pattern Batch 9 - Closed-Syllable Monophthongs ('ă/â/ê/ô/ơ/ư') & SimpleTelex Free-Order (15 tests)
            ("test_326_breve_a_closed_codas_all_orders", test_326_breve_a_closed_codas_all_orders),
            ("test_327_breve_a_dot_and_delayed_d_all_orders", test_327_breve_a_dot_and_delayed_d_all_orders),
            ("test_328_circumflex_a_closed_codas_all_orders", test_328_circumflex_a_closed_codas_all_orders),
            ("test_329_circumflex_e_closed_codas_all_orders", test_329_circumflex_e_closed_codas_all_orders),
            ("test_330_circumflex_o_closed_codas_all_orders", test_330_circumflex_o_closed_codas_all_orders),
            ("test_331_horn_o_closed_codas_all_orders", test_331_horn_o_closed_codas_all_orders),
            ("test_332_horn_u_closed_codas_all_orders", test_332_horn_u_closed_codas_all_orders),
            ("test_333_simple_telex_free_order_moiws_nguoiwf_truongwf", test_333_simple_telex_free_order_moiws_nguoiwf_truongwf),
            ("test_334_simple_telex_free_order_circumflex_and_breve", test_334_simple_telex_free_order_circumflex_and_breve),
            ("test_335_simple_telex_backspace_mid_and_across_space", test_335_simple_telex_backspace_mid_and_across_space),
            ("test_336_backspace_mid_closed_monophthong_tasmw", test_336_backspace_mid_closed_monophthong_tasmw),
            ("test_337_backspace_mid_closed_monophthong_cosmo", test_337_backspace_mid_closed_monophthong_cosmo),
            ("test_338_backspace_across_space_demesd", test_338_backspace_across_space_demesd),
            ("test_339_line_positions_start_mid_end_batch9", test_339_line_positions_start_mid_end_batch9),
            ("test_340_sentence_real_world_batch9", test_340_sentence_real_world_batch9),

            // Section 18: Scheduled Pattern Batch 10 - 'trời/đời/khởi', 'rượu/khướu/bướu' & Code-Switching + Backspace (15 tests)
            ("test_341_troi_all_6_permutations", test_341_troi_all_6_permutations),
            ("test_342_doi_all_permutations_with_delayed_d", test_342_doi_all_permutations_with_delayed_d),
            ("test_343_khoi_loi_ngoi_all_orders", test_343_khoi_loi_ngoi_all_orders),
            ("test_344_ruou_all_orders", test_344_ruou_all_orders),
            ("test_345_khuou_buou_all_orders", test_345_khuou_buou_all_orders),
            ("test_346_code_switching_vietnamese_and_english_keywords", test_346_code_switching_vietnamese_and_english_keywords),
            ("test_347_code_switching_with_backspace_and_edit", test_347_code_switching_with_backspace_and_edit),
            ("test_348_backspace_mid_ruouwj", test_348_backspace_mid_ruouwj),
            ("test_349_backspace_mid_khuouws", test_349_backspace_mid_khuouws),
            ("test_350_backspace_across_space_troiwf", test_350_backspace_across_space_troiwf),
            ("test_351_line_positions_start_mid_end_batch10", test_351_line_positions_start_mid_end_batch10),
            ("test_352_vni_troi_doi_ruou_all_orders", test_352_vni_troi_doi_ruou_all_orders),
            ("test_353_full_line_delete_and_retype_across_multiple_words", test_353_full_line_delete_and_retype_across_multiple_words),
            ("test_354_multi_sentence_backspace_stress_test", test_354_multi_sentence_backspace_stress_test),
            ("test_355_sentence_real_world_batch10", test_355_sentence_real_world_batch10),
        ]
    }
}
