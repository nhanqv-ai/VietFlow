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

    // =========================================================================
    // MARK: - Section 19: Long-Essay & Code Review Batch 1 (15 tests)
    // =========================================================================

    func test_356_gi_early_tone_before_shorthand_w() {
        XCTAssertEqual(apply("gixw giwx gixwa giwax gifwong giwfong giswong girwong"), "giữ giữ giữa giữa giường giường giướng giưởng")
    }

    func test_357_multi_syllable_english_auto_restore_er_or_en() {
        let input = "number member center render doctor editor monitor author tailor modern header router tokens container pointer"
        XCTAssertEqual(apply(input), input)
    }

    func test_358_multi_syllable_english_auto_restore_first_syllable_tone() {
        let input = "server service version person target market garden carbon margin normal formal portal airport airlines"
        XCTAssertEqual(apply(input), input)
    }

    func test_359_multi_syllable_english_auto_restore_diacritic_suffix() {
        let input = "shadow window follow yellow bamboo yahoo degree agree"
        XCTAssertEqual(apply(input), input)
    }

    func test_360_double_press_undo_vs_non_adjacent_absorption() {
        XCTAssertEqual(apply("uoww truwongwf nguwoiwf dduwocwj tiensge nguyxene duwocjd"), "uow trường người được tiếng nguyễn được")
    }

    func test_361_long_essay_literature_ha_noi_mua_thu_full() {
        let cleanInput = "Haf Nooij muaf thu, caay cowm nguooij vafng caay bafng las ddor, nawfm keef been nhau phoos xwa nhaf coor mais ngois thaam naau. Nhwngx buoior chieufe se lajnh, huowng hoa suxwa ngatj ngafo bay qua twfng con dduongwf nhor. Nguoiwf Haf Nooij ddi dajo quanh hoof Guowm, gixw giwax tim mifnh nhwngx kyr nieemj ddepj nhaats cuar thuowr moiws biets yeusez thuowng."
        let cleanExpected = "Hà Nội mùa thu, cây cơm nguội vàng cây bàng lá đỏ, nằm kề bên nhau phố xưa nhà cổ mái ngói thâm nâu. Những buổi chiều se lạnh, hương hoa sữa ngạt ngào bay qua từng con đường nhỏ. Người Hà Nội đi dạo quanh hồ Gươm, giữ giữa tim mình những kỷ niệm đẹp nhất của thuở mới biết yêu thương."
        XCTAssertEqual(apply(cleanInput), cleanExpected)
    }

    func test_362_long_essay_literature_with_heavy_backspace_edits() {
        let input = "Haf Nooij muaf<BS>a thu, caay cowm nguooij vafng caay bafng las ddor, nawfm keef been nhau phoos suxwa<BS><BS><BS>xwa nhaf coor mais ngois thaam ddaauf<BS><BS><BS>naau. Khi tooi moiws<BS>is ddeens ddaay, tooi ddax thwr swar laji twfng doofng<BS><BS><BS>ofng chwx vieets tay ddeer luuw gixw<BS>wx trojn venj khoanhr khawcs giao muaf tuyeetj vowif."
        let expected = "Hà Nội mùa thu, cây cơm nguội vàng cây bàng lá đỏ, nằm kề bên nhau phố xưa nhà cổ mái ngói thâm nâu. Khi tôi mới đến đây, tôi đã thử sửa lại từng dòng chữ viết tay để lưu giữ trọn vẹn khoảnh khắc giao mùa tuyệt vời."
        XCTAssertEqual(apply(input), expected)
    }

    func test_363_long_essay_software_engineering_and_devops() {
        let input = "Trong heej thoongs phaan tiasn<BS><BS><BS>ans hiejn ddaij, mooix<BS>ix server vaf service ddeeuf chayj trong container cuar docker, ketes noois qua router vaf kieemr tra tokens trong header. Khi monitor phats hiejn number luwowjng request tawng cao, author vaf member trong nhosm sex mowr<BS>owr editor hoawcj terminal ddeer swar code swift, caapj nhaatj version moiws vaf push leen github."
        let expected = "Trong hệ thống phân tán hiện đại, mỗi server và service đều chạy trong container của docker, kết nối qua router và kiểm tra tokens trong header. Khi monitor phát hiện number lượng request tăng cao, author và member trong nhóm sẽ mở editor hoặc terminal để sửa code swift, cập nhật version mới và push lên github."
        XCTAssertEqual(apply(input), expected)
    }

    func test_364_long_essay_software_engineering_with_backspace_edits() {
        let input = "Chusng tooi suwr dujng pattern moiws<BS>is ddeer toosi uuw<BS>u buffer trong terminal: khi nguoiwf dufng gox nhaafm<BS><BS>aafm hoawcj nhaans backspace lieen tucj, heej thoongs vaanx<BS>nx gixw nguyeen trangj thais<BS>is chisnh<BS><BS>nh xacs mafn<BS> khoong bij looxi font hay nhary chwx."
        let expected = "Chúng tôi sử dụng pattern mới để tối ưu buffer trong terminal: khi người dùng gõ nhầm hoặc nhấn backspace liên tục, hệ thống vẫn giữ nguyên trạng thái chính xác mà không bị lỗi font hay nhảy chữ."
        XCTAssertEqual(apply(input), expected)
    }

    func test_365_long_essay_journalism_economy_and_society() {
        let input = "Nawm 2026, neefn kinh tees Vieetj Nam ghi nhaanj buwowcs chuyeenr mifnh manhj mex vowis toocs ddooj tawng truwongwr aasn tuwowngj. Nhieefu duwj asn haj taafng giao thoong trojng ddieemr, twf dduongwf cao toocs Bawcs Nam ddeens saan bay quoocs tees, ddax dduwocj trieenr khai ddoofng booj, gops phaafn naang cao ddoiwf soongs cuar hafng trieeuj nguoiwf daan."
        let expected = "Năm 2026, nền kinh tế Việt Nam ghi nhận bước chuyển mình mạnh mẽ với tốc độ tăng trưởng ấn tượng. Nhiều dự án hạ tầng giao thông trọng điểm, từ đường cao tốc Bắc Nam đến sân bay quốc tế, đã được triển khai đồng bộ, góp phần nâng cao đời sống của hàng triệu người dân."
        XCTAssertEqual(apply(input), expected)
    }

    func test_366_long_essay_journalism_with_backspace_edits() {
        let input = "Theo baos caos moiws nhaats<BS>ts, tyr leej chuyeenr ddooir soos taij cacs doanh nghieepj vwaf vaf nhor ddax vuowjt muwcs 85%. Nguoiwf lao ddoojng ngayf cafng chur<BS>ur ddoojng hocj hoir cacs<BS>cs kyx nawng moiws ddeer thichs uwngs vowis<BS>is suwj thay ddooir nhanh chongs cuar thij truwongwf."
        let expected = "Theo báo cáo mới nhất, tỷ lệ chuyển đổi số tại các doanh nghiệp vừa và nhỏ đã vượt mức 85%. Người lao động ngày càng chủ động học hỏi các kỹ năng mới để thích ứng với sự thay đổi nhanh chóng của thị trường."
        XCTAssertEqual(apply(input), expected)
    }

    func test_367_long_dialogue_multiline_conversation() {
        let input = "- Chaof banj, dajo nayf coong vieecj owr truwongwf thees nafo rooif?\n- Camr own banj, mifnh vaanx<BS>nx ddang baanj hoafn thieenj duwj asn VietFlow cho heej ddieeuf hafnh macos.\n- Tuyeejt<BS>tj vowif quas! Mifnh vwaf taiwr<BS><BS>r version moiws veef dufng thwr, gox tieengs Vieetj mwowtj maf vaf swar looxi backspace cuwcj kyf chuanra!"
        let expected = "- Chào bạn, dạo này công việc ở trường thế nào rồi?\n- Cảm ơn bạn, mình vẫn đang bận hoàn thiện dự án VietFlow cho hệ điều hành macos.\n- Tuyệt vời quá! Mình vừa tải version mới về dùng thử, gõ tiếng Việt mượt mà và sửa lỗi backspace cực kỳ chuẩn!"
        XCTAssertEqual(apply(input), expected)
    }

    func test_368_long_essay_vni_mixed_orders_and_numbers() {
        let input = "Ha2 No6i5 mu2a thu, ca6y co7m nguo6i5 va2ng ca6y ba2ng la1 d9o3. Ngu7o7i2<BS>i2 Ha2 No6i5 luo6n giu74 trong tim nhu7ng4 ky3 nie6m5 d9e5p nha6t1 cu3a thuo73 mo7i1<BS>i1 bu7o7c1 va2o tru7o7ng2."
        let expected = "Hà Nội mùa thu, cây cơm nguội vàng cây bàng lá đỏ. Người Hà Nội luôn giữ trong tim những kỷ niệm đẹp nhất của thuở mới bước vào trường."
        XCTAssertEqual(apply(input, engine: vniEngine), expected)
    }

    func test_369_long_essay_traditional_tone_style() {
        let tradEngine = makeEngine(inputMethod: .telex, tonePlacement: .traditional)
        let input = "Giwax khuoong<BS>n vieen truwongwf hocj, nhwngx canhf<BS><BS>nhf hoa phuwowngj ddor rwcj hoaf cufng asnh nawsng muaf hef, mang laji baauf khoong khis vui ver, khoer khoawsn vaf trafn ddaafy suwcs soongs."
        let expected = "Giữa khuôn viên trường học, những cành hoa phượng đỏ rực hoà cùng ánh nắng mùa hè, mang lại bầu không khí vui vẻ, khoẻ khoắn và tràn đầy sức sống."
        XCTAssertEqual(apply(input, engine: tradEngine), expected)
    }

    func test_370_long_essay_simple_telex_mode() {
        let simpleEngine = makeEngine(inputMethod: .simpleTelex, tonePlacement: .modern)
        let input = "Ngayf<BS>yf xa xuwa<BS>a khi tooi moiws buowcs vafo truwongwf, tooi ddax gapwj nhuwngx nguoiwf banj thaajt tuyeetj vowif beenk<BS> khung cuwra soor."
        let expected = "Ngày xa xưa khi tôi mới bước vào trường, tôi đã gặp những người bạn thật tuyệt vời bên khung cửa sổ."
        XCTAssertEqual(apply(input, engine: simpleEngine), expected)
    }

    // =========================================================================
    // MARK: - Section 20: Long-Essay & Code Review Batch 2 (15 Tests)
    // =========================================================================

    func test_371_howacj_xowans_khowan_early_w_after_o_before_a() {
        let input = "howacj howajc hojwac xowans xowasn xoswan khowan ngowatj ngowajt ngojwat thowats thowast"
        let expected = "hoặc hoặc hoặc xoắn xoắn xoắn khoăn ngoặt ngoặt ngoặt thoắt thoắt"
        XCTAssertEqual(apply(input), expected)
    }

    func test_372_single_syllable_english_invalid_coda_auto_restore() {
        let input = "card hard yard ward bird girl curl world work fork pork dark mark park bark"
        let expected = "card hard yard ward bird girl curl world work fork pork dark mark park bark"
        XCTAssertEqual(apply(input), expected)
    }

    func test_373_double_vowel_english_invalid_coda_auto_restore() {
        let input = "good mood wood hood book look took cook hook tool pool cool feel heel need seed week seek"
        let expected = "good mood wood hood book look took cook hook tool pool cool feel heel need seed week seek"
        XCTAssertEqual(apply(input), expected)
    }

    func test_374_english_coda_k_and_b_and_f_auto_restore() {
        let input = "desk mask task risk disk ask bank tank rank link sink pink verb herb curb surf turf"
        let expected = "desk mask task risk disk ask bank tank rank link sink pink verb herb curb surf turf"
        XCTAssertEqual(apply(input), expected)
    }

    func test_375_dak_lak_valid_vietnamese_coda_k_preserved() {
        let input = "DDawks Lawks ddawks lawks"
        let expected = "Đắk Lắk đắk lắk"
        XCTAssertEqual(apply(input), expected)
    }

    func test_376_long_essay_history_and_culture_viet_nam() {
        let input = "Trari qua hafng nghifn nawm lijch swr dwjng nuwowsc vaf gixw nuwowsc, twf thuowr cacs vua Hufng dwjng nuwowsc Vawn Lang cho ddeens thoiwf ddaij moiws ngayf nay, nguoiwf Vieetj Nam luoon gixw gifn banr sawcs vawn hoas truyeenf thoosng toots ddejp. Nhwngx caau chuyeenj coor tichs, nhwngx lafn ddieeju daan ca quan hoj muwowtj maf, tieengs ddafn baauf ngaan nga giwax ddeem trawng thanh bifnh hay hifnh anhr mais ddifnh, beesn nuwowsc, caay dda ddaauf lafng ddax in saau vafo taam khamr cuar bieets bao thees heej nguoiwf con ddaats Vieetj."
        let expected = "Trải qua hàng nghìn năm lịch sử dựng nước và giữ nước, từ thuở các vua Hùng dựng nước Văn Lang cho đến thời đại mới ngày nay, người Việt Nam luôn giữ gìn bản sắc văn hóa truyền thống tốt đẹp. Những câu chuyện cổ tích, những làn điệu dân ca quan họ mượt mà, tiếng đàn bầu ngân nga giữa đêm trăng thanh bình hay hình ảnh mái đình, bến nước, cây đa đầu làng đã in sâu vào tâm khảm của biết bao thế hệ người con đất Việt."
        XCTAssertEqual(apply(input), expected)
    }

    func test_377_long_essay_history_and_culture_with_heavy_backspace() {
        let input = "Trari qua hafng nghifn nawm lijch swr dwjng nuwowsc vaf gixw<BS>wx nuwowsc, twf thuowx<BS>owr cacs vua Hufng dwjng nuwowsc Vawn Lang cho ddeens thoiwf ddaij moiws<BS>i ngayf nay, nguoiwf Vieetj Nam luoon gixw gifn banr sawcs vawn hoas truyeenf<BS>n thoosng toots ddejp."
        let expected = "Trải qua hàng nghìn năm lịch sử dựng nước và giữ nước, từ thuở các vua Hùng dựng nước Văn Lang cho đến thời đại mới ngày nay, người Việt Nam luôn giữ gìn bản sắc văn hóa truyền thống tốt đẹp."
        XCTAssertEqual(apply(input), expected)
    }

    func test_378_long_essay_fullstack_engineering_code_switching() {
        let input = "Khi lamf work hard treen desk, developer caafn kieemr tra task, risk vaf card thanh toasn qua bank. Neeus server gawpj looxi, hayx dufng tool ddeer xem log trong book, look vafo pool ketes noois, giri<BS><BS>wri link baos caos cho team trong week nayf."
        let expected = "Khi làm work hard trên desk, developer cần kiểm tra task, risk và card thanh toán qua bank. Nếu server gặp lỗi, hãy dùng tool để xem log trong book, look vào pool kết nối, gửi link báo cáo cho team trong week này."
        XCTAssertEqual(apply(input), expected)
    }

    func test_379_long_essay_fullstack_engineering_with_backspace() {
        let input = "Khi lamf work<BS><BS>rk hard treen desk, developer caafn kieemr tra task, risk vaf card thanh toasn qua bank. Neeus<BS>u server gawpj looxi, hayx dufng tool<BS>l ddeer xem log trong book<BS>k, look vafo pool ketes<BS>t noois vaf swar<BS>a ngay trong week nayf."
        let expected = "Khi làm work hard trên desk, developer cần kiểm tra task, risk và card thanh toán qua bank. Nếu server gặp lỗi, hãy dùng tool để xem log trong book, look vào pool kết nối và sửa ngay trong week này."
        XCTAssertEqual(apply(input), expected)
    }

    func test_380_long_essay_parentheses_brackets_quotes_urls_emails() {
        let input = "Duwj asn \"VietFlow\" (booj gox tieengs Vieetj toocs ddooj cao [macOS]) cos kho max nguoofn taij https://github.com/nhanqv-ai/VietFlow; moij thawsng<BS><BS>cs mawcs xin gwir veef support@vietflow.vn howacj truy caapj portal/header-center."
        let expected = "Dự án \"VietFlow\" (bộ gõ tiếng Việt tốc độ cao [macOS]) có kho mã nguồn tại https://github.com/nhanqv-ai/VietFlow; mọi thắc mắc xin gửi về support@vietflow.vn hoặc truy cập portal/header-center."
        XCTAssertEqual(apply(input), expected)
    }

    func test_381_long_essay_uppercase_headings_and_mixed_case() {
        let input = "CHUWOWNG MOOJT: HAFNH TRIFNH DDOOIR MOIWS VAF PHAST TRIEERN BEENF VWXNG CUAR DDAATS NUWOWSC VIEETJ NAM TRONG KYR NGUYEEN SOOS HOAS"
        let expected = "CHƯƠNG MỘT: HÀNH TRÌNH ĐỔI MỚI VÀ PHÁT TRIỂN BỀN VỮNG CỦA ĐẤT NƯỚC VIỆT NAM TRONG KỶ NGUYÊN SỐ HÓA"
        XCTAssertEqual(apply(input), expected)
    }

    func test_382_long_essay_scientific_medicine_and_environment() {
        let input = "Con dduongwf khucs khuyur ngoawnf ngoeof daanx qua nhwngx rwfng caay raajm rapj, nowi coong tacs baor toofn ddoojng vaatj hoang dax nhuw huowu sao, khuwous vaf cacs loafi chim quys hieems ddang dduwocj trieenr khai howacj mowr roojng."
        let expected = "Con đường khúc khuỷu ngoằn ngoèo dẫn qua những rừng cây rậm rạp, nơi công tác bảo tồn động vật hoang dã như hươu sao, khướu và các loài chim quý hiếm đang được triển khai hoặc mở rộng."
        XCTAssertEqual(apply(input), expected)
    }

    func test_383_long_essay_scientific_with_heavy_backspace() {
        let input = "Con dduongwf khucs khuyur<BS>u ngoawnf<BS>n ngoeof daanx<BS>n qua nhwngx<BS>g rwfng caay rur<BS>aajm rapj, nowi coong<BS>g tacs baor<BS>o toofn<BS>n ddoojng vaatj hoang dax nhuw huowu<BS>u sao, khuwous<BS>u vaf cacs loafi chim quys<BS>ys hieems ddang dduwocj<BS>c trieenr khai howacj<BS>c mowr roojng."
        let expected = "Con đường khúc khuỷu ngoằn ngoèo dẫn qua những rừng cây rậm rạp, nơi công tác bảo tồn động vật hoang dã như hươu sao, khướu và các loài chim quý hiếm đang được triển khai hoặc mở rộng."
        XCTAssertEqual(apply(input), expected)
    }

    func test_384_long_essay_vni_complex_mixed_english_and_numbers() {
        let input = "Na8m 2026, 100% he65 tho6ng1 server tre6n macos d9a4 d9u7o75c na6ng ca6p1 le6n 64GB RAM va2 ma2n hi2nh 120Hz, giu1p ngu7o7i2 du2ng go4 tie6ng1 Vie6t5 mu7o75t ma2 tu72 thuo73 mo7i1<BS>i1 ba8t1 d9a6u2."
        let expected = "Năm 2026, 100% hệ thống server trên macos đã được nâng cấp lên 64GB RAM và màn hình 120Hz, giúp người dùng gõ tiếng Việt mượt mà từ thuở mới bắt đầu."
        XCTAssertEqual(apply(input, engine: vniEngine), expected)
    }

    func test_385_stress_test_delete_entire_paragraph_and_retype() {
        let firstSentence = "Muaf thu Haf Nooij ddejp diju dafng vowis huowng cooms moiws."
        let firstExpected = "Mùa thu Hà Nội đẹp dịu dàng với hương cốm mới."
        XCTAssertEqual(apply(firstSentence), firstExpected)
        let bsCount = firstExpected.count
        let backspaces = String(repeating: "<BS>", count: bsCount)
        let secondSentence = "Nguoiwf Vieetj Nam twj hafo veef truyeenf thoosng vawn hoas ngafn nawm vawn hieens."
        let secondExpected = "Người Việt Nam tự hào về truyền thống văn hóa ngàn năm văn hiến."
        XCTAssertEqual(apply(firstSentence + backspaces + secondSentence), secondExpected)
    }

    // MARK: - Section 21: Regression Coverage for Backspace and Duplicate Coda (3 tests)
    func test_386_backspace_deleted_g_then_type_n_preserves_ascii_and_recovers_vietnamese_ng() {
        // ASCII words without 'uon' or diacritics retain the second 'n' when typing after '<BS>'
        engine.reset()
        XCTAssertEqual(apply("dang<BS>n"), "dann")
        engine.reset()
        XCTAssertEqual(apply("bang<BS>n"), "bann")
        // Vietnamese syllables ending in -ng recover cleanly when retyping 'ng' after '<BS>'
        engine.reset()
        XCTAssertEqual(apply("truong<BS>ngwf"), "trường")
        engine.reset()
        XCTAssertEqual(apply("ddong<BS>ngof"), "đồng")
        engine.reset()
        XCTAssertEqual(apply("vafng<BS>ng"), "vàng")
    }

    func test_387_duplicate_coda_consonant_suppression_on_vietnamese_syllables() {
        // Vietnamese syllables with diacritics/tones suppress duplicate 'n' and 'c'
        engine.reset()
        XCTAssertEqual(apply("khuoonn"), "khuôn")
        engine.reset()
        XCTAssertEqual(apply("khuoong<BS>n"), "khuôn")
        engine.reset()
        XCTAssertEqual(apply("hocjc"), "học")
        engine.reset()
        XCTAssertEqual(apply("cacsc"), "các")
        engine.reset()
        XCTAssertEqual(apply("toanss"), "toans")
        // While ASCII abbreviations and English words retain duplicate codas
        engine.reset()
        XCTAssertEqual(apply("cc"), "cc")
        engine.reset()
        XCTAssertEqual(apply("bcc"), "bcc")
        engine.reset()
        XCTAssertEqual(apply("gcc"), "gcc")
        engine.reset()
        XCTAssertEqual(apply("pccc"), "pccc")
        engine.reset()
        XCTAssertEqual(apply("nn"), "nn")
        engine.reset()
        XCTAssertEqual(apply("cnn"), "cnn")
        engine.reset()
        XCTAssertEqual(apply("acc"), "acc")
        engine.reset()
        XCTAssertEqual(apply("ann"), "ann")
        engine.reset()
        XCTAssertEqual(apply("inn"), "inn")
    }

    func test_388_ascii_control_characters_reset_engine_buffer() {
        engine.reset()
        _ = engine.processKey("v")
        _ = engine.processKey("i")
        XCTAssertEqual(engine.currentSyllable, "vi")
        // Non-printable control character \u{7F} (Forward Delete) or \u{1B} (Escape) resets buffer
        let delta = engine.processKey("\u{7F}")
        XCTAssertNil(delta)
        XCTAssertEqual(engine.currentSyllable, "")

        _ = engine.processKey("n")
        _ = engine.processKey("a")
        _ = engine.processKey("m")
        XCTAssertEqual(engine.currentSyllable, "nam")
        let escDelta = engine.processKey("\u{1B}")
        XCTAssertNil(escDelta)
        XCTAssertEqual(engine.currentSyllable, "")
    }

    func test_389_backspace_across_technical_separator_restores_active_syllable() {
        engine.reset()
        // 1. Vietnamese compound across technical separator: delete separator and tone preceding syllable
        XCTAssertEqual(apply("toan_hoc<BS><BS><BS><BS>s"), "toán")

        // 2. Variable identifier: delete separator and continue appending word suffix
        engine.reset()
        XCTAssertEqual(apply("user_name<BS><BS><BS><BS><BS>s"), "users")

        // 3. Hyphenated identifier: delete separator and edit preceding onset/rhyme
        engine.reset()
        XCTAssertEqual(apply("my-app<BS><BS><BS><BS><BS>inh"), "minh")

        // 4. Dotted filename: delete extension and dot separator, continue typing filename
        engine.reset()
        XCTAssertEqual(apply("file.txt<BS><BS><BS><BS>r"), "filer")

        // 5. Slash path: delete trailing segments across multiple separators
        engine.reset()
        XCTAssertEqual(apply("a/b/c<BS><BS><BS><BS>nh"), "anh")
    }

    func test_390_deep_backspace_across_technical_separators_and_mixed_bypass() {
        engine.reset()
        // 1. Vietnamese word before separator when following segment was bypassed (e.g. toan_abc)
        // Deleting separator should NOT inherit wasBypassed from abc, allowing tone modification on preceding syllable
        XCTAssertEqual(apply("toan_abc<BS><BS><BS><BS>s"), "toán")

        // 2. Deeper backspace through restored English word after deleting separator
        engine.reset()
        _ = apply("file.txt<BS><BS><BS><BS><BS>")
        XCTAssertEqual(engine.currentSyllable, "fil")

        // 2b. English keyword before separator: backspacing into restored keyword preserves syllable without wiping
        engine.reset()
        _ = apply("data_user<BS><BS><BS><BS><BS><BS>")
        XCTAssertEqual(engine.currentSyllable, "dat")

        // 3. Backspacing deeper and typing new letters on restored English segment
        engine.reset()
        XCTAssertEqual(apply("file.txt<BS><BS><BS><BS><BS><BS>nd"), "find")
        XCTAssertEqual(engine.currentSyllable, "find")

        // 4. Multi-level path backspacing across multiple separators
        engine.reset()
        XCTAssertEqual(apply("src/test.txt<BS><BS><BS><BS><BS><BS>mp"), "src/temp")
        XCTAssertEqual(engine.currentSyllable, "src/temp")

        // 5. Vietnamese word followed by technical extension / bypassed identifier
        engine.reset()
        XCTAssertEqual(apply("viet_app<BS><BS><BS><BS>j"), "việt")
        XCTAssertEqual(engine.currentSyllable, "việt")

        // 6. Email address multi-step backspace across multiple separators (@ and .)
        engine.reset()
        XCTAssertEqual(apply("admin@site.vn<BS><BS><BS><BS><BS><BS><BS><BS><BS><BS>user"), "admuser")
        XCTAssertEqual(engine.currentSyllable, "admuser")

        // 7. VNI mode: backspace across technical separator and apply numeric tone
        let vniEngine = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        let vniResult = applyKeystrokesAndBackspacesToScreenBuffer("toan_hoc<BS><BS><BS><BS>1", engine: vniEngine)
        XCTAssertEqual(vniResult, "toán")
        XCTAssertEqual(vniEngine.currentSyllable, "toán")
    }

    func test_391_backspace_across_compound_words_2_and_3_syllables() {
        engine.reset()
        // 1. Two-syllable compound: delete entire second syllable (3 chars) and tone preceding syllable
        XCTAssertEqual(apply("thafnhphoos<BS><BS><BS>r"), "thảnh")
        XCTAssertEqual(engine.currentSyllable, "thảnh")

        // 2. Two-syllable compound: delete second syllable + 1 char of first syllable, then tone
        engine.reset()
        XCTAssertEqual(apply("thafnhphoos<BS><BS><BS><BS>r"), "thản")
        XCTAssertEqual(engine.currentSyllable, "thản")

        // 3. Two-syllable compound: delete second syllable (5 chars), change tone to grave
        engine.reset()
        XCTAssertEqual(apply("hairphofng<BS><BS><BS><BS><BS>f"), "hài")
        XCTAssertEqual(engine.currentSyllable, "hài")

        // 4. Two-syllable compound: delete second syllable (5 chars), then delete 'i' of 'hải' (6th BS), type 'o' -> 'hảo'
        engine.reset()
        XCTAssertEqual(apply("hairphofng<BS><BS><BS><BS><BS><BS>o"), "hảo")
        XCTAssertEqual(engine.currentSyllable, "hảo")

        // 5. Three-syllable compound: delete 3rd syllable (3 chars), tone 2nd syllable
        engine.reset()
        XCTAssertEqual(apply("hairphofngbawcs<BS><BS><BS>s"), "hảiphóng")
        XCTAssertEqual(engine.currentSyllable, "hảiphóng")

        // 6. Three-syllable compound: delete 3rd (3 chars) and 2nd syllables (5 chars), tone 1st syllable
        engine.reset()
        XCTAssertEqual(apply("hairphofngbawcs<BS><BS><BS><BS><BS><BS><BS><BS>f"), "hài")
        XCTAssertEqual(engine.currentSyllable, "hài")

        // 7. Compound word across space with backspace: delete space (1) and 2nd syllable (3 chars), tone 1st syllable
        engine.reset()
        XCTAssertEqual(apply("tooi thafnhphoos <BS><BS><BS><BS>r"), "tôi thảnh")
        XCTAssertEqual(engine.currentSyllable, "thảnh")

        // 8. Deep delete through compound word (7 chars) and space (1 char), tone previous word
        engine.reset()
        XCTAssertEqual(apply("tooi vieetjnam<BS><BS><BS><BS><BS><BS><BS><BS>s"), "tối")
        XCTAssertEqual(engine.currentSyllable, "tối")

        // 9. VNI mode: delete 2nd syllable of compound word (3 chars) and tone 1st syllable
        let vniEngine = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        let vniResult = applyKeystrokesAndBackspacesToScreenBuffer("vie6t5nam<BS><BS><BS>1", engine: vniEngine)
        XCTAssertEqual(vniResult, "viết")
        XCTAssertEqual(vniEngine.currentSyllable, "viết")

        // 10. VNI mode: 3-syllable compound word backspace 3rd syllable (3 chars) and tone 2nd syllable
        vniEngine.reset()
        let vniResult3 = applyKeystrokesAndBackspacesToScreenBuffer("hai3pho2ngba81c<BS><BS><BS>1", engine: vniEngine)
        XCTAssertEqual(vniResult3, "hảiphóng")
        XCTAssertEqual(vniEngine.currentSyllable, "hảiphóng")
    }

    // MARK: - Section 22: Backspace Across Punctuation / Delimiters & Double-Tone Undo Recovery (2 tests)
    func test_392_backspace_across_punctuation_and_bracket_boundaries() {
        engine.reset()
        // 1. Comma boundary: delete comma and modify tone
        XCTAssertEqual(apply("moiws,<BS>f"), "mời")
        engine.reset()
        XCTAssertEqual(apply("toans,<BS>f"), "toàn")
        engine.reset()
        // 2. Comma boundary: delete comma and backspace syllable to edit vowel
        XCTAssertEqual(apply("moiws,<BS><BS>r"), "mở")
        engine.reset()
        XCTAssertEqual(apply("toans,<BS><BS>r"), "tỏa")
        // 3. Comma followed by space: multi-step backspace deletes space and comma, then tones
        engine.reset()
        XCTAssertEqual(apply("moiws, <BS><BS>f"), "mời")
        engine.reset()
        XCTAssertEqual(apply("toans, <BS><BS>f"), "toàn")
        engine.reset()
        XCTAssertEqual(apply("moiws, <BS><BS><BS>r"), "mở")
        // 4. Exclamation and question mark boundaries
        engine.reset()
        XCTAssertEqual(apply("moiws!<BS>f"), "mời")
        engine.reset()
        XCTAssertEqual(apply("moiws?<BS>f"), "mời")
        engine.reset()
        XCTAssertEqual(apply("toans!<BS>j"), "toạn")
        engine.reset()
        XCTAssertEqual(apply("toans?<BS>x"), "toãn")
        // 5. Colon and semicolon boundaries
        engine.reset()
        XCTAssertEqual(apply("moiws:<BS>f"), "mời")
        engine.reset()
        XCTAssertEqual(apply("moiws;<BS>f"), "mời")
        // 6. Brackets and quotation boundaries
        engine.reset()
        XCTAssertEqual(apply("(moiws)<BS>f"), "(mời")
        engine.reset()
        XCTAssertEqual(apply("[moiws]<BS>f"), "[mời")
        engine.reset()
        XCTAssertEqual(apply("{moiws}<BS>f"), "{mời")
        engine.reset()
        XCTAssertEqual(apply("\"moiws\"<BS>f"), "\"mời")
        engine.reset()
        XCTAssertEqual(apply("'moiws'<BS>f"), "'mời")
        engine.reset()
        XCTAssertEqual(apply("\"toans\"<BS>f"), "\"toàn")
        // 7. VNI mode across punctuation
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("moi71,<BS>2", engine: vniEng), "mời")
        vniEng.reset()
        XCTAssertEqual(apply("toan1,<BS>2", engine: vniEng), "toàn")
        vniEng.reset()
        XCTAssertEqual(apply("toan1, <BS><BS>2", engine: vniEng), "toàn")
        vniEng.reset()
        XCTAssertEqual(apply("(moi71)<BS>2", engine: vniEng), "(mời")
    }

    func test_393_double_tone_undo_followed_by_backspace_and_retyping() {
        engine.reset()
        // 1. Double-key tone undo followed by Backspace and retyping tone key
        XCTAssertEqual(apply("bass<BS>s"), "bá")
        engine.reset()
        XCTAssertEqual(apply("barr<BS>r"), "bả")
        engine.reset()
        XCTAssertEqual(apply("baff<BS>f"), "bà")
        engine.reset()
        XCTAssertEqual(apply("baxx<BS>x"), "bã")
        engine.reset()
        XCTAssertEqual(apply("bajj<BS>j"), "bạ")
        engine.reset()
        XCTAssertEqual(apply("toanss<BS>s"), "toán")
        engine.reset()
        XCTAssertEqual(apply("toanff<BS>f"), "toàn")
        engine.reset()
        XCTAssertEqual(apply("mejj<BS>j"), "mẹ")
        engine.reset()
        XCTAssertEqual(apply("ngurr<BS>r"), "ngủ")
        engine.reset()
        XCTAssertEqual(apply("cass<BS>s"), "cá")

        // 2. Double-key tone undo followed by multi-step Backspace and new onset/rhyme
        engine.reset()
        XCTAssertEqual(apply("bass<BS><BS>o"), "bo")
        engine.reset()
        XCTAssertEqual(apply("barr<BS><BS>o"), "bo")
        engine.reset()
        XCTAssertEqual(apply("toanss<BS><BS><BS>e"), "toe")
        engine.reset()
        XCTAssertEqual(apply("bass<BS><BS><BS>c"), "c")

        // 3. Double-key tone undo continuation without desync
        engine.reset()
        XCTAssertEqual(apply("basses"), "basses")
        engine.reset()
        XCTAssertEqual(apply("tarrget"), "target")
        engine.reset()
        XCTAssertEqual(apply("carrpet"), "carpet")
    }

    func test_394_double_diacritic_undo_followed_by_backspace_and_retyping() {
        engine.reset()
        // 1. Telex double diacritic mark undo followed by Backspace and retyping diacritic trigger key
        XCTAssertEqual(apply("baaa<BS>a"), "bâ")
        engine.reset()
        XCTAssertEqual(apply("beee<BS>e"), "bê")
        engine.reset()
        XCTAssertEqual(apply("booo<BS>o"), "bô")
        engine.reset()
        XCTAssertEqual(apply("caww<BS>w"), "că")
        engine.reset()
        XCTAssertEqual(apply("moww<BS>w"), "mơ")
        engine.reset()
        XCTAssertEqual(apply("tuww<BS>w"), "tư")
        engine.reset()
        XCTAssertEqual(apply("muoww<BS>w"), "mươ")
        engine.reset()
        XCTAssertEqual(apply("ddd<BS>d"), "đ")

        // 2. Double diacritic undo followed by Backspace and new tone key
        engine.reset()
        XCTAssertEqual(apply("baaa<BS>s"), "bá")
        engine.reset()
        XCTAssertEqual(apply("beee<BS>f"), "bè")
        engine.reset()
        XCTAssertEqual(apply("booo<BS>r"), "bỏ")
        engine.reset()
        XCTAssertEqual(apply("caww<BS>x"), "cã")
        engine.reset()
        XCTAssertEqual(apply("moww<BS>j"), "mọ")
        engine.reset()
        XCTAssertEqual(apply("tuww<BS>s"), "tú")

        // 3. Double diacritic undo followed by multi-step Backspace and new vowel / onset
        engine.reset()
        XCTAssertEqual(apply("baaa<BS><BS>o"), "bo")
        engine.reset()
        XCTAssertEqual(apply("beee<BS><BS>a"), "ba")
        engine.reset()
        XCTAssertEqual(apply("booo<BS><BS>e"), "be")
        engine.reset()
        XCTAssertEqual(apply("caww<BS><BS>o"), "co")
        engine.reset()
        XCTAssertEqual(apply("moww<BS><BS>a"), "ma")
        engine.reset()
        XCTAssertEqual(apply("tuww<BS><BS>e"), "te")
        engine.reset()
        XCTAssertEqual(apply("muoww<BS><BS><BS>a"), "ma")
        engine.reset()
        XCTAssertEqual(apply("baaa<BS><BS><BS>c"), "c")
        engine.reset()
        XCTAssertEqual(apply("ddda<BS><BS>d"), "đ")

        // 4. Double diacritic undo continuation without desync (English keywords/shorthand)
        engine.reset()
        XCTAssertEqual(apply("baaat"), "baat")
        engine.reset()
        XCTAssertEqual(apply("beeer"), "beer")
        engine.reset()
        XCTAssertEqual(apply("boook"), "book")
        engine.reset()
        XCTAssertEqual(apply("cawws"), "caws")
        engine.reset()
        XCTAssertEqual(apply("mowws"), "mows")
        engine.reset()
        XCTAssertEqual(apply("tuwwu"), "tuwu")
        engine.reset()
        XCTAssertEqual(apply("dddo"), "ddo")

        // 5. VNI double diacritic undo followed by Backspace and retyping
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("ca66<BS>6", engine: vniEng), "câ")
        vniEng.reset()
        XCTAssertEqual(apply("be66<BS>6", engine: vniEng), "bê")
        vniEng.reset()
        XCTAssertEqual(apply("co66<BS>6", engine: vniEng), "cô")
        vniEng.reset()
        XCTAssertEqual(apply("co77<BS>7", engine: vniEng), "cơ")
        vniEng.reset()
        XCTAssertEqual(apply("cu77<BS>7", engine: vniEng), "cư")
        vniEng.reset()
        XCTAssertEqual(apply("ca88<BS>8", engine: vniEng), "că")
        vniEng.reset()
        XCTAssertEqual(apply("d99<BS>9", engine: vniEng), "đ")
        vniEng.reset()
        XCTAssertEqual(apply("ca66<BS>1", engine: vniEng), "cá")
        vniEng.reset()
        XCTAssertEqual(apply("co77<BS>2", engine: vniEng), "cò")
        vniEng.reset()
        XCTAssertEqual(apply("ca66<BS><BS>e", engine: vniEng), "ce")
    }

    func test_395_compound_word_boundary_double_consonants_and_collocation_backspace_recovery() {
        engine.reset()
        // 1. Vietnamese compound words with boundary consonants matching English medial double consonants
        XCTAssertEqual(apply("lamfmowis"), "làmmới")
        engine.reset()
        XCTAssertEqual(apply("timfmua"), "tìmmua")
        engine.reset()
        XCTAssertEqual(apply("mawtjtoois"), "mặttối")
        engine.reset()
        XCTAssertEqual(apply("vieetjtaan"), "việttân")
        engine.reset()
        XCTAssertEqual(apply("nhaapjphongf"), "nhậpphòng")

        // 2. Collocation backspace recovery across space: boons koons and taams kaams
        engine.reset()
        XCTAssertEqual(apply("boons koons <BS><BS><BS><BS>koons"), "bốn kốn")
        engine.reset()
        XCTAssertEqual(apply("boons koons <BS><BS><BS><BS><BS> koons"), "bốn kốn")
        engine.reset()
        XCTAssertEqual(apply("taams kaams <BS><BS><BS><BS>kaams"), "tấm kấm")
        engine.reset()
        XCTAssertEqual(apply("taams kaams <BS><BS><BS><BS><BS> kaams"), "tấm kấm")

        // 3. Unlatched k-, p-, g-, ng- coda backspace & retype/tone override
        engine.reset()
        XCTAssertEqual(apply("peensf<BS>n"), "pền")
        engine.reset()
        XCTAssertEqual(apply("peensj<BS>t"), "pệt")
        engine.reset()
        XCTAssertEqual(apply("peensf<BS>m"), "pềm")
        engine.reset()
        XCTAssertEqual(apply("boons koons<BS>n"), "bốn kốn")
        engine.reset()
        XCTAssertEqual(apply("taams kaams<BS>m"), "tấm kấm")
        engine.reset()
        XCTAssertEqual(apply("taams kaams<BS>p"), "tấm kấp")
        engine.reset()
        XCTAssertEqual(apply("ddeens geens<BS>n"), "đến gến")

        // 4. Preserving spaceHistory across technical separators
        engine.reset()
        XCTAssertEqual(apply("xin chafo anh-em<BS><BS><BS><BS><BS><BS><BS>s"), "xin cháo")
    }

    func test_396_delayed_diacritic_double_key_undo_and_backspace_retyping() {
        engine.reset()
        // 1. Telex delayed 'd' double-key undo on vowels & codas
        XCTAssertEqual(apply("didd"), "did")
        engine.reset()
        XCTAssertEqual(apply("dadd"), "dad")
        engine.reset()
        XCTAssertEqual(apply("dodd"), "dod")
        engine.reset()
        XCTAssertEqual(apply("dudd"), "dud")
        engine.reset()
        XCTAssertEqual(apply("dedd"), "ded")
        engine.reset()
        XCTAssertEqual(apply("DIDD"), "DID")
        engine.reset()
        XCTAssertEqual(apply("DADD"), "DAD")

        // 2. Telex delayed horn & breve double-key undo across codas
        engine.reset()
        XCTAssertEqual(apply("toanww"), "toanw")

        // 3. VNI delayed '9' double-key undo on vowels & codas
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("di99", engine: vniEng), "di9")
        vniEng.reset()
        XCTAssertEqual(apply("da99", engine: vniEng), "da9")
        vniEng.reset()
        XCTAssertEqual(apply("do99", engine: vniEng), "do9")
        vniEng.reset()
        XCTAssertEqual(apply("du99", engine: vniEng), "du9")
        vniEng.reset()
        XCTAssertEqual(apply("de99", engine: vniEng), "de9")
        vniEng.reset()
        XCTAssertEqual(apply("DI99", engine: vniEng), "DI9")
        vniEng.reset()
        XCTAssertEqual(apply("DA99", engine: vniEng), "DA9")

        // 4. VNI delayed breve double-key undo across codas
        vniEng.reset()
        XCTAssertEqual(apply("toan88", engine: vniEng), "toan8")

        // 5. Backspace and retyping after delayed diacritic double-key undo
        engine.reset()
        XCTAssertEqual(apply("didd<BS>d"), "đi")
        engine.reset()
        XCTAssertEqual(apply("dadd<BS>d"), "đa")
        engine.reset()
        XCTAssertEqual(apply("toanww<BS>w"), "toăn")
        engine.reset()
        XCTAssertEqual(apply("didd<BS><BS>a"), "da")

        vniEng.reset()
        XCTAssertEqual(apply("di99<BS>9", engine: vniEng), "đi")
        vniEng.reset()
        XCTAssertEqual(apply("da99<BS>9", engine: vniEng), "đa")
        vniEng.reset()
        XCTAssertEqual(apply("toan88<BS>8", engine: vniEng), "toăn")
        vniEng.reset()
        XCTAssertEqual(apply("di99<BS><BS>a", engine: vniEng), "da")
    }

    func test_397_uppercase_toned_diacritic_double_key_undo_and_backspace_retyping() {
        engine.reset()
        // 1. Telex uppercase toned diacritic double-key undo across tones
        XCTAssertEqual(apply("COSOO"), "CÓO")
        engine.reset()
        XCTAssertEqual(apply("COFOO"), "CÒO")
        engine.reset()
        XCTAssertEqual(apply("COROO"), "CỎO")
        engine.reset()
        XCTAssertEqual(apply("COXOO"), "CÕO")
        engine.reset()
        XCTAssertEqual(apply("COJOO"), "CỌO")

        engine.reset()
        XCTAssertEqual(apply("COSWW"), "CÓW")
        engine.reset()
        XCTAssertEqual(apply("COFWW"), "CÒW")
        engine.reset()
        XCTAssertEqual(apply("CORWW"), "CỎW")
        engine.reset()
        XCTAssertEqual(apply("COXWW"), "CÕW")
        engine.reset()
        XCTAssertEqual(apply("COJWW"), "CỌW")

        engine.reset()
        XCTAssertEqual(apply("TUSWW"), "TÚW")
        engine.reset()
        XCTAssertEqual(apply("TUFWW"), "TÙW")
        engine.reset()
        XCTAssertEqual(apply("TURWW"), "TỦW")
        engine.reset()
        XCTAssertEqual(apply("TUXWW"), "TŨW")
        engine.reset()
        XCTAssertEqual(apply("TUJWW"), "TỤW")

        engine.reset()
        XCTAssertEqual(apply("OSOO"), "ÓO")
        engine.reset()
        XCTAssertEqual(apply("OSWW"), "ÓW")
        engine.reset()
        XCTAssertEqual(apply("USWW"), "ÚW")
        engine.reset()
        XCTAssertEqual(apply("ASWW"), "ÁW")
        engine.reset()
        XCTAssertEqual(apply("CASWW"), "CÁW")

        // 2. VNI uppercase toned diacritic double-key undo across tones
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("CO166", engine: vniEng), "CÓ6")
        vniEng.reset()
        XCTAssertEqual(apply("CO266", engine: vniEng), "CÒ6")
        vniEng.reset()
        XCTAssertEqual(apply("CO366", engine: vniEng), "CỎ6")
        vniEng.reset()
        XCTAssertEqual(apply("CO466", engine: vniEng), "CÕ6")
        vniEng.reset()
        XCTAssertEqual(apply("CO566", engine: vniEng), "CỌ6")

        vniEng.reset()
        XCTAssertEqual(apply("CO177", engine: vniEng), "CÓ7")
        vniEng.reset()
        XCTAssertEqual(apply("CO277", engine: vniEng), "CÒ7")
        vniEng.reset()
        XCTAssertEqual(apply("CO377", engine: vniEng), "CỎ7")
        vniEng.reset()
        XCTAssertEqual(apply("CO477", engine: vniEng), "CÕ7")
        vniEng.reset()
        XCTAssertEqual(apply("CO577", engine: vniEng), "CỌ7")

        vniEng.reset()
        XCTAssertEqual(apply("TU177", engine: vniEng), "TÚ7")
        vniEng.reset()
        XCTAssertEqual(apply("TU277", engine: vniEng), "TÙ7")
        vniEng.reset()
        XCTAssertEqual(apply("TU377", engine: vniEng), "TỦ7")
        vniEng.reset()
        XCTAssertEqual(apply("TU477", engine: vniEng), "TŨ7")
        vniEng.reset()
        XCTAssertEqual(apply("TU577", engine: vniEng), "TỤ7")

        vniEng.reset()
        XCTAssertEqual(apply("A188", engine: vniEng), "Á8")
        vniEng.reset()
        XCTAssertEqual(apply("CA188", engine: vniEng), "CÁ8")
        vniEng.reset()
        XCTAssertEqual(apply("CA288", engine: vniEng), "CÀ8")

        // 3. Backspace and retyping after uppercase toned diacritic double-key undo
        engine.reset()
        XCTAssertEqual(apply("COSOO<BS>O"), "CỐ")
        engine.reset()
        XCTAssertEqual(apply("COSWW<BS>W"), "CỚ")
        engine.reset()
        XCTAssertEqual(apply("TUSWW<BS>W"), "TỨ")

        vniEng.reset()
        XCTAssertEqual(apply("CO166<BS>6", engine: vniEng), "CỐ")
        vniEng.reset()
        XCTAssertEqual(apply("CO177<BS>7", engine: vniEng), "CỚ")
        vniEng.reset()
        XCTAssertEqual(apply("TU177<BS>7", engine: vniEng), "TỨ")
        vniEng.reset()
        XCTAssertEqual(apply("A188<BS>8", engine: vniEng), "Ắ")
    }

    func test_398_toned_dual_horn_diacritic_double_key_undo_and_backspace_retyping() {
        engine.reset()
        // 1. Telex lowercase toned dual-horn undo across 5 tones
        XCTAssertEqual(apply("cuosww"), "cúow")
        engine.reset()
        XCTAssertEqual(apply("cuofww"), "cùow")
        engine.reset()
        XCTAssertEqual(apply("cuorww"), "củow")
        engine.reset()
        XCTAssertEqual(apply("cuoxww"), "cũow")
        engine.reset()
        XCTAssertEqual(apply("cuojww"), "cụow")

        // 2. Telex uppercase toned dual-horn undo across 5 tones
        engine.reset()
        XCTAssertEqual(apply("CUOSWW"), "CÚOW")
        engine.reset()
        XCTAssertEqual(apply("CUOFWW"), "CÙOW")
        engine.reset()
        XCTAssertEqual(apply("CUORWW"), "CỦOW")
        engine.reset()
        XCTAssertEqual(apply("CUOXWW"), "CŨOW")
        engine.reset()
        XCTAssertEqual(apply("CUOJWW"), "CỤOW")

        // 3. Telex standalone zero onset across tones
        engine.reset()
        XCTAssertEqual(apply("uosww"), "úow")
        engine.reset()
        XCTAssertEqual(apply("uofww"), "ùow")
        engine.reset()
        XCTAssertEqual(apply("UOSWW"), "ÚOW")
        engine.reset()
        XCTAssertEqual(apply("UOFWW"), "ÙOW")

        // 4. VNI lowercase toned dual-horn undo across 5 tones
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("cuo177", engine: vniEng), "cúo7")
        vniEng.reset()
        XCTAssertEqual(apply("cuo277", engine: vniEng), "cùo7")
        vniEng.reset()
        XCTAssertEqual(apply("cuo377", engine: vniEng), "củo7")
        vniEng.reset()
        XCTAssertEqual(apply("cuo477", engine: vniEng), "cũo7")
        vniEng.reset()
        XCTAssertEqual(apply("cuo577", engine: vniEng), "cụo7")

        // 5. VNI uppercase toned dual-horn undo across 5 tones
        vniEng.reset()
        XCTAssertEqual(apply("CUO177", engine: vniEng), "CÚO7")
        vniEng.reset()
        XCTAssertEqual(apply("CUO277", engine: vniEng), "CÙO7")
        vniEng.reset()
        XCTAssertEqual(apply("CUO377", engine: vniEng), "CỦO7")
        vniEng.reset()
        XCTAssertEqual(apply("CUO477", engine: vniEng), "CŨO7")
        vniEng.reset()
        XCTAssertEqual(apply("CUO577", engine: vniEng), "CỤO7")

        // 6. VNI standalone zero onset across tones
        vniEng.reset()
        XCTAssertEqual(apply("uo177", engine: vniEng), "úo7")
        vniEng.reset()
        XCTAssertEqual(apply("UO177", engine: vniEng), "ÚO7")

        // 7. Backspace and retyping after toned dual-horn undo
        engine.reset()
        XCTAssertEqual(apply("cuosww<BS>w"), "cướ")
        engine.reset()
        XCTAssertEqual(apply("CUOSWW<BS>W"), "CƯỚ")

        vniEng.reset()
        XCTAssertEqual(apply("cuo177<BS>7", engine: vniEng), "cướ")
        vniEng.reset()
        XCTAssertEqual(apply("CUO177<BS>7", engine: vniEng), "CƯỚ")
    }

    func test_399_coda_and_offglide_dual_horn_diacritic_double_key_undo_and_backspace_retyping() {
        engine.reset()
        // 1. Telex dual-horn undo with coda consonants across tones
        XCTAssertEqual(apply("cuongsww"), "cuóngw")
        engine.reset()
        XCTAssertEqual(apply("cuongfww"), "cuòngw")
        engine.reset()
        XCTAssertEqual(apply("cuongrww"), "cuỏngw")
        engine.reset()
        XCTAssertEqual(apply("cuongxww"), "cuõngw")
        engine.reset()
        XCTAssertEqual(apply("cuongjww"), "cuọngw")

        engine.reset()
        XCTAssertEqual(apply("cuocjww"), "cuọcw")
        engine.reset()
        XCTAssertEqual(apply("cuocsww"), "cuócw")
        engine.reset()
        XCTAssertEqual(apply("cuonsww"), "cuónw")
        engine.reset()
        XCTAssertEqual(apply("cuotsww"), "cuótw")
        engine.reset()
        XCTAssertEqual(apply("cuomsww"), "cuómw")
        engine.reset()
        XCTAssertEqual(apply("cuopsww"), "cuópw")

        // 2. Untoned dual-horn undo with codas & off-glides
        engine.reset()
        XCTAssertEqual(apply("cuongww"), "cuongw")
        engine.reset()
        XCTAssertEqual(apply("cuocww"), "cuocw")
        engine.reset()
        XCTAssertEqual(apply("cuonww"), "cuonw")
        engine.reset()
        XCTAssertEqual(apply("cuoiww"), "cuoiw")
        engine.reset()
        XCTAssertEqual(apply("cuouww"), "cuouw")

        // 3. Telex dual-horn undo with off-glides
        engine.reset()
        XCTAssertEqual(apply("cuoisww"), "cuóiw")
        engine.reset()
        XCTAssertEqual(apply("cuoifww"), "cuòiw")
        engine.reset()
        XCTAssertEqual(apply("ruoujww"), "ruọuw")
        engine.reset()
        XCTAssertEqual(apply("huousww"), "huóuw")

        // 4. Telex uppercase dual-horn undo with codas & off-glides
        engine.reset()
        XCTAssertEqual(apply("CUONGSWW"), "CUÓNGW")
        engine.reset()
        XCTAssertEqual(apply("CUOCJWW"), "CUỌCW")
        engine.reset()
        XCTAssertEqual(apply("CUOISWW"), "CUÓIW")
        engine.reset()
        XCTAssertEqual(apply("CUONGWW"), "CUONGW")
        engine.reset()
        XCTAssertEqual(apply("CUOIWW"), "CUOIW")

        // 5. VNI dual-horn undo with codas & off-glides
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("cuong177", engine: vniEng), "cuóng7")
        vniEng.reset()
        XCTAssertEqual(apply("cuong277", engine: vniEng), "cuòng7")
        vniEng.reset()
        XCTAssertEqual(apply("cuoc577", engine: vniEng), "cuọc7")
        vniEng.reset()
        XCTAssertEqual(apply("cuoi177", engine: vniEng), "cuói7")
        vniEng.reset()
        XCTAssertEqual(apply("ruou577", engine: vniEng), "ruọu7")
        vniEng.reset()
        XCTAssertEqual(apply("CUONG177", engine: vniEng), "CUÓNG7")
        vniEng.reset()
        XCTAssertEqual(apply("CUOC577", engine: vniEng), "CUỌC7")
        vniEng.reset()
        XCTAssertEqual(apply("CUOI177", engine: vniEng), "CUÓI7")
        vniEng.reset()
        XCTAssertEqual(apply("cuong77", engine: vniEng), "cuong7")
        vniEng.reset()
        XCTAssertEqual(apply("CUONG77", engine: vniEng), "CUONG7")

        // 6. Backspace and retyping after dual-horn undo with codas & off-glides
        engine.reset()
        XCTAssertEqual(apply("cuongsww<BS>w"), "cướng")
        engine.reset()
        XCTAssertEqual(apply("CUONGSWW<BS>W"), "CƯỚNG")
        engine.reset()
        XCTAssertEqual(apply("cuocjww<BS>w"), "cược")
        engine.reset()
        XCTAssertEqual(apply("cuoisww<BS>w"), "cưới")
        engine.reset()
        XCTAssertEqual(apply("cuongww<BS>w"), "cương")

        vniEng.reset()
        XCTAssertEqual(apply("cuong177<BS>7", engine: vniEng), "cướng")
        vniEng.reset()
        XCTAssertEqual(apply("CUONG177<BS>7", engine: vniEng), "CƯỚNG")
        vniEng.reset()
        XCTAssertEqual(apply("cuoc577<BS>7", engine: vniEng), "cược")
    }

    func test_400_circumflex_breve_stroke_diacritic_double_key_undo_with_codas_and_tones() {
        // 1. Telex circumflex (a/e/o) double-key undo on syllables with codas and tones
        engine.reset()
        XCTAssertEqual(apply("cansaa"), "cána")
        engine.reset()
        XCTAssertEqual(apply("canfaa"), "càna")
        engine.reset()
        XCTAssertEqual(apply("canraa"), "cảna")
        engine.reset()
        XCTAssertEqual(apply("canxaa"), "cãna")
        engine.reset()
        XCTAssertEqual(apply("canjaa"), "cạna")
        engine.reset()
        XCTAssertEqual(apply("catsaa"), "cáta")

        engine.reset()
        XCTAssertEqual(apply("congsoo"), "cóngo")
        engine.reset()
        XCTAssertEqual(apply("congfoo"), "còngo")
        engine.reset()
        XCTAssertEqual(apply("congroo"), "cỏngo")
        engine.reset()
        XCTAssertEqual(apply("congxoo"), "cõngo")
        engine.reset()
        XCTAssertEqual(apply("congjoo"), "cọngo")

        engine.reset()
        XCTAssertEqual(apply("denfee"), "dène")

        // 2. Telex breve (w) double-key undo on syllables with codas and tones
        engine.reset()
        XCTAssertEqual(apply("toansww"), "toánw")
        engine.reset()
        XCTAssertEqual(apply("cansww"), "cánw")
        engine.reset()
        XCTAssertEqual(apply("catsww"), "cátw")

        // 3. Telex delayed stroke (d) double-key undo on syllables with tones
        engine.reset()
        XCTAssertEqual(apply("disdd"), "díd")
        engine.reset()
        XCTAssertEqual(apply("dasdd"), "dád")
        engine.reset()
        XCTAssertEqual(apply("dangfdd"), "dàngd")

        // 4. Uppercase circumflex, breve, stroke double-key undo with codas & tones
        engine.reset()
        XCTAssertEqual(apply("CANSAA"), "CÁNA")
        engine.reset()
        XCTAssertEqual(apply("CONGSOO"), "CÓNGO")
        engine.reset()
        XCTAssertEqual(apply("TOANSWW"), "TOÁNW")
        engine.reset()
        XCTAssertEqual(apply("DISDD"), "DÍD")

        // 5. VNI circumflex (6), breve (8), stroke (9) double-key undo with codas & tones
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("can166", engine: vniEng), "cán6")
        vniEng.reset()
        XCTAssertEqual(apply("cong166", engine: vniEng), "cóng6")
        vniEng.reset()
        XCTAssertEqual(apply("den166", engine: vniEng), "dén6")
        vniEng.reset()
        XCTAssertEqual(apply("toan188", engine: vniEng), "toán8")
        vniEng.reset()
        XCTAssertEqual(apply("can188", engine: vniEng), "cán8")
        vniEng.reset()
        XCTAssertEqual(apply("di199", engine: vniEng), "dí9")
        vniEng.reset()
        XCTAssertEqual(apply("CAN166", engine: vniEng), "CÁN6")
        vniEng.reset()
        XCTAssertEqual(apply("CONG166", engine: vniEng), "CÓNG6")
        vniEng.reset()
        XCTAssertEqual(apply("TOAN188", engine: vniEng), "TOÁN8")
        vniEng.reset()
        XCTAssertEqual(apply("DI199", engine: vniEng), "DÍ9")

        // 6. Backspace and retyping after double-key undo across codas and tones
        engine.reset()
        XCTAssertEqual(apply("cansaa<BS>a"), "cấn")
        engine.reset()
        XCTAssertEqual(apply("congsoo<BS>o"), "cống")
        engine.reset()
        XCTAssertEqual(apply("denfee<BS>e"), "dền")
        engine.reset()
        XCTAssertEqual(apply("toansww<BS>w"), "toắn")
        engine.reset()
        XCTAssertEqual(apply("disdd<BS>d"), "đí")
        engine.reset()
        XCTAssertEqual(apply("CANSAA<BS>A"), "CẤN")
        engine.reset()
        XCTAssertEqual(apply("CONGSOO<BS>O"), "CỐNG")

        vniEng.reset()
        XCTAssertEqual(apply("can166<BS>6", engine: vniEng), "cấn")
        vniEng.reset()
        XCTAssertEqual(apply("cong166<BS>6", engine: vniEng), "cống")
        vniEng.reset()
        XCTAssertEqual(apply("toan188<BS>8", engine: vniEng), "toắn")
        vniEng.reset()
        XCTAssertEqual(apply("di199<BS>9", engine: vniEng), "đí")
    }

    func test_401_offglide_diphthong_circumflex_and_untoned_stroke_diacritic_double_key_undo() {
        // 1. Telex circumflex (a/e/o) double-key undo on off-glides and diphthongs with tones
        engine.reset()
        XCTAssertEqual(apply("caysaa"), "cáya")
        engine.reset()
        XCTAssertEqual(apply("cayfaa"), "càya")
        engine.reset()
        XCTAssertEqual(apply("cayraa"), "cảya")
        engine.reset()
        XCTAssertEqual(apply("cayxaa"), "cãya")
        engine.reset()
        XCTAssertEqual(apply("cayjaa"), "cạya")

        engine.reset()
        XCTAssertEqual(apply("causaa"), "cáua")
        engine.reset()
        XCTAssertEqual(apply("cauxaa"), "cãua")

        engine.reset()
        XCTAssertEqual(apply("toisoo"), "tóio")
        engine.reset()
        XCTAssertEqual(apply("chuoisoo"), "chuóio")

        engine.reset()
        XCTAssertEqual(apply("neusee"), "néue")
        engine.reset()
        XCTAssertEqual(apply("tieusee"), "tiéue")
        engine.reset()
        XCTAssertEqual(apply("thuesee"), "thúee")

        // 2. Telex toned stroke onset double-key undo across codas
        engine.reset()
        XCTAssertEqual(apply("dangsdd"), "dángd")
        engine.reset()
        XCTAssertEqual(apply("dangrdd"), "dảngd")
        engine.reset()
        XCTAssertEqual(apply("dangxdd"), "dãngd")
        engine.reset()
        XCTAssertEqual(apply("dangjdd"), "dạngd")

        // 3. Uppercase circumflex and stroke double-key undo on off-glides
        engine.reset()
        XCTAssertEqual(apply("CAYSAA"), "CÁYA")
        engine.reset()
        XCTAssertEqual(apply("CAUSAA"), "CÁUA")
        engine.reset()
        XCTAssertEqual(apply("TOISOO"), "TÓIO")
        engine.reset()
        XCTAssertEqual(apply("CHUOISOO"), "CHUÓIO")
        engine.reset()
        XCTAssertEqual(apply("NEUSEE"), "NÉUE")
        engine.reset()
        XCTAssertEqual(apply("DANGSDD"), "DÁNGD")

        // 4. VNI circumflex double-key undo on off-glides and toned stroke onset
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("cay166", engine: vniEng), "cáy6")
        vniEng.reset()
        XCTAssertEqual(apply("cau166", engine: vniEng), "cáu6")
        vniEng.reset()
        XCTAssertEqual(apply("toi166", engine: vniEng), "tói6")
        vniEng.reset()
        XCTAssertEqual(apply("chuoi166", engine: vniEng), "chuói6")
        vniEng.reset()
        XCTAssertEqual(apply("neu166", engine: vniEng), "néu6")
        vniEng.reset()
        XCTAssertEqual(apply("dang199", engine: vniEng), "dáng9")
        vniEng.reset()
        XCTAssertEqual(apply("CAY166", engine: vniEng), "CÁY6")
        vniEng.reset()
        XCTAssertEqual(apply("TOI166", engine: vniEng), "TÓI6")
        vniEng.reset()
        XCTAssertEqual(apply("DANG199", engine: vniEng), "DÁNG9")

        // 5. Backspace and retyping after double-key undo across off-glides and stroke onset
        engine.reset()
        XCTAssertEqual(apply("caysaa<BS>a"), "cấy")
        engine.reset()
        XCTAssertEqual(apply("causaa<BS>a"), "cấu")
        engine.reset()
        XCTAssertEqual(apply("toisoo<BS>o"), "tối")
        engine.reset()
        XCTAssertEqual(apply("chuoisoo<BS>o"), "chuối")
        engine.reset()
        XCTAssertEqual(apply("neusee<BS>e"), "nếu")
        engine.reset()
        XCTAssertEqual(apply("tieusee<BS>e"), "tiếu")
        engine.reset()
        XCTAssertEqual(apply("thuesee<BS>e"), "thuế")
        engine.reset()
        XCTAssertEqual(apply("dangsdd<BS>d"), "đáng")
        engine.reset()
        XCTAssertEqual(apply("CAYSAA<BS>A"), "CẤY")
        engine.reset()
        XCTAssertEqual(apply("TOISOO<BS>O"), "TỐI")
        engine.reset()
        XCTAssertEqual(apply("DANGSDD<BS>D"), "ĐÁNG")

        vniEng.reset()
        XCTAssertEqual(apply("cay166<BS>6", engine: vniEng), "cấy")
        vniEng.reset()
        XCTAssertEqual(apply("cau166<BS>6", engine: vniEng), "cấu")
        vniEng.reset()
        XCTAssertEqual(apply("toi166<BS>6", engine: vniEng), "tối")
        vniEng.reset()
        XCTAssertEqual(apply("chuoi166<BS>6", engine: vniEng), "chuối")
        vniEng.reset()
        XCTAssertEqual(apply("neu166<BS>6", engine: vniEng), "nếu")
        vniEng.reset()
        XCTAssertEqual(apply("dang199<BS>9", engine: vniEng), "đáng")
    }

    func test_402_open_diphthong_circumflex_double_key_undo_and_backspace_retyping() {
        // 1. Telex circumflex (o/e/a) double-key undo on open diphthongs and triphthongs across 5 tones
        engine.reset()
        XCTAssertEqual(apply("muosoo"), "múoo")
        engine.reset()
        XCTAssertEqual(apply("muofoo"), "mùoo")
        engine.reset()
        XCTAssertEqual(apply("muoroo"), "mủoo")
        engine.reset()
        XCTAssertEqual(apply("muoxoo"), "mũoo")
        engine.reset()
        XCTAssertEqual(apply("muojoo"), "mụoo")

        engine.reset()
        XCTAssertEqual(apply("tiesee"), "tíee")
        engine.reset()
        XCTAssertEqual(apply("tiefee"), "tìee")
        engine.reset()
        XCTAssertEqual(apply("tieree"), "tỉee")
        engine.reset()
        XCTAssertEqual(apply("tiexee"), "tĩee")
        engine.reset()
        XCTAssertEqual(apply("tiejee"), "tịee")

        engine.reset()
        XCTAssertEqual(apply("khuasaa"), "khúaa")
        engine.reset()
        XCTAssertEqual(apply("khuafaa"), "khùaa")
        engine.reset()
        XCTAssertEqual(apply("khuaraa"), "khủaa")
        engine.reset()
        XCTAssertEqual(apply("khuaxaa"), "khũaa")
        engine.reset()
        XCTAssertEqual(apply("khuajaa"), "khụaa")

        engine.reset()
        XCTAssertEqual(apply("khuyesee"), "khuýee")

        // 2. Uppercase open diphthong circumflex double-key undo
        engine.reset()
        XCTAssertEqual(apply("MUOSOO"), "MÚOO")
        engine.reset()
        XCTAssertEqual(apply("TIESEE"), "TÍEE")
        engine.reset()
        XCTAssertEqual(apply("KHUASAA"), "KHÚAA")
        engine.reset()
        XCTAssertEqual(apply("KHUYESEE"), "KHUÝEE")

        // 3. VNI open diphthong circumflex double-key undo
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("muo166", engine: vniEng), "múo6")
        vniEng.reset()
        XCTAssertEqual(apply("tie166", engine: vniEng), "tíe6")
        vniEng.reset()
        XCTAssertEqual(apply("khua166", engine: vniEng), "khúa6")
        vniEng.reset()
        XCTAssertEqual(apply("khuye166", engine: vniEng), "khuýe6")
        vniEng.reset()
        XCTAssertEqual(apply("MUO166", engine: vniEng), "MÚO6")
        vniEng.reset()
        XCTAssertEqual(apply("TIE166", engine: vniEng), "TÍE6")
        vniEng.reset()
        XCTAssertEqual(apply("KHUA166", engine: vniEng), "KHÚA6")
        vniEng.reset()
        XCTAssertEqual(apply("KHUYE166", engine: vniEng), "KHUÝE6")

        // 4. Backspace and retyping after open diphthong circumflex double-key undo
        engine.reset()
        XCTAssertEqual(apply("muosoo<BS>o"), "muố")
        engine.reset()
        XCTAssertEqual(apply("tiesee<BS>e"), "tiế")
        engine.reset()
        XCTAssertEqual(apply("khuasaa<BS>a"), "khuấ")
        engine.reset()
        XCTAssertEqual(apply("khuyesee<BS>e"), "khuyế")

        engine.reset()
        XCTAssertEqual(apply("MUOSOO<BS>O"), "MUỐ")
        engine.reset()
        XCTAssertEqual(apply("TIESEE<BS>E"), "TIẾ")
        engine.reset()
        XCTAssertEqual(apply("KHUASAA<BS>A"), "KHUẤ")
        engine.reset()
        XCTAssertEqual(apply("KHUYESEE<BS>E"), "KHUYẾ")

        vniEng.reset()
        XCTAssertEqual(apply("muo166<BS>6", engine: vniEng), "muố")
        vniEng.reset()
        XCTAssertEqual(apply("tie166<BS>6", engine: vniEng), "tiế")
        vniEng.reset()
        XCTAssertEqual(apply("khua166<BS>6", engine: vniEng), "khuấ")
        vniEng.reset()
        XCTAssertEqual(apply("khuye166<BS>6", engine: vniEng), "khuyế")
    }

    func test_403_onglide_ye_tone_placement_and_circumflex_double_key_undo() {
        // 1. Telex on-glide diphthong ye tone placement across tones
        engine.reset()
        XCTAssertEqual(apply("yef"), "yè")
        engine.reset()
        XCTAssertEqual(apply("yer"), "yẻ")
        engine.reset()
        XCTAssertEqual(apply("yex"), "yẽ")
        engine.reset()
        XCTAssertEqual(apply("yej"), "yẹ")
        engine.reset()
        XCTAssertEqual(apply("Yef"), "Yè")
        engine.reset()
        XCTAssertEqual(apply("Yer"), "Yẻ")
        engine.reset()
        XCTAssertEqual(apply("Yex"), "Yẽ")
        engine.reset()
        XCTAssertEqual(apply("Yej"), "Yẹ")
        engine.reset()
        XCTAssertEqual(apply("YEF"), "YÈ")
        engine.reset()
        XCTAssertEqual(apply("YER"), "YẺ")
        engine.reset()
        XCTAssertEqual(apply("YEX"), "YẼ")
        engine.reset()
        XCTAssertEqual(apply("YEJ"), "YẸ")

        // 2. VNI on-glide diphthong ye tone placement across 5 tones
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("ye1", engine: vniEng), "yé")
        vniEng.reset()
        XCTAssertEqual(apply("ye2", engine: vniEng), "yè")
        vniEng.reset()
        XCTAssertEqual(apply("ye3", engine: vniEng), "yẻ")
        vniEng.reset()
        XCTAssertEqual(apply("ye4", engine: vniEng), "yẽ")
        vniEng.reset()
        XCTAssertEqual(apply("ye5", engine: vniEng), "yẹ")
        vniEng.reset()
        XCTAssertEqual(apply("Ye1", engine: vniEng), "Yé")
        vniEng.reset()
        XCTAssertEqual(apply("Ye2", engine: vniEng), "Yè")
        vniEng.reset()
        XCTAssertEqual(apply("Ye3", engine: vniEng), "Yẻ")
        vniEng.reset()
        XCTAssertEqual(apply("Ye4", engine: vniEng), "Yẽ")
        vniEng.reset()
        XCTAssertEqual(apply("Ye5", engine: vniEng), "Yẹ")
        vniEng.reset()
        XCTAssertEqual(apply("YE1", engine: vniEng), "YÉ")
        vniEng.reset()
        XCTAssertEqual(apply("YE2", engine: vniEng), "YÈ")
        vniEng.reset()
        XCTAssertEqual(apply("YE3", engine: vniEng), "YẺ")
        vniEng.reset()
        XCTAssertEqual(apply("YE4", engine: vniEng), "YẼ")
        vniEng.reset()
        XCTAssertEqual(apply("YE5", engine: vniEng), "YẸ")

        // 3. Traditional tone placement style unanimity on on-glide diphthong ye
        let tradEng = makeEngine(inputMethod: .telex, tonePlacement: .traditional)
        XCTAssertEqual(apply("yef", engine: tradEng), "yè")
        tradEng.reset()
        XCTAssertEqual(apply("yer", engine: tradEng), "yẻ")
        tradEng.reset()
        XCTAssertEqual(apply("yex", engine: tradEng), "yẽ")
        tradEng.reset()
        XCTAssertEqual(apply("yej", engine: tradEng), "yẹ")

        let tradVniEng = makeEngine(inputMethod: .vni, tonePlacement: .traditional)
        XCTAssertEqual(apply("ye1", engine: tradVniEng), "yé")
        tradVniEng.reset()
        XCTAssertEqual(apply("ye2", engine: tradVniEng), "yè")
        tradVniEng.reset()
        XCTAssertEqual(apply("ye3", engine: tradVniEng), "yẻ")
        tradVniEng.reset()
        XCTAssertEqual(apply("ye4", engine: tradVniEng), "yẽ")
        tradVniEng.reset()
        XCTAssertEqual(apply("ye5", engine: tradVniEng), "yẹ")

        // 4. TonePlacementEngine targetVowelIndex direct unit precision tests
        XCTAssertEqual(TonePlacementEngine.targetVowelIndex(vowels: ["y", "e"], onset: "", coda: "", style: .modern), 1)
        XCTAssertEqual(TonePlacementEngine.targetVowelIndex(vowels: ["y", "e"], onset: "", coda: "", style: .traditional), 1)
        XCTAssertEqual(TonePlacementEngine.targetVowelIndex(vowels: ["Y", "E"], onset: "", coda: "", style: .modern), 1)
        XCTAssertEqual(TonePlacementEngine.targetVowelIndex(vowels: ["y", "a"], onset: "", coda: "", style: .modern), 1)
        XCTAssertEqual(TonePlacementEngine.targetVowelIndex(vowels: ["y", "a"], onset: "", coda: "", style: .traditional), 1)
        XCTAssertEqual(TonePlacementEngine.targetVowelIndex(vowels: ["y", "o"], onset: "", coda: "", style: .modern), 1)
        XCTAssertEqual(TonePlacementEngine.targetVowelIndex(vowels: ["y", "u"], onset: "", coda: "", style: .modern), 1)
        XCTAssertEqual(TonePlacementEngine.targetVowelIndex(vowels: ["i", "u"], onset: "d", coda: "", style: .modern), 0)
        XCTAssertEqual(TonePlacementEngine.targetVowelIndex(vowels: ["ư", "u"], onset: "c", coda: "", style: .modern), 0)

        // 5. Telex open circumflex double-key undo on ye across tones
        engine.reset()
        XCTAssertEqual(apply("yefee"), "yèe")
        engine.reset()
        XCTAssertEqual(apply("yeree"), "yẻe")
        engine.reset()
        XCTAssertEqual(apply("yexee"), "yẽe")
        engine.reset()
        XCTAssertEqual(apply("yejee"), "yẹe")
        engine.reset()
        XCTAssertEqual(apply("Yefee"), "Yèe")
        engine.reset()
        XCTAssertEqual(apply("Yeree"), "Yẻe")
        engine.reset()
        XCTAssertEqual(apply("Yexee"), "Yẽe")
        engine.reset()
        XCTAssertEqual(apply("Yejee"), "Yẹe")
        engine.reset()
        XCTAssertEqual(apply("YEFEE"), "YÈE")
        engine.reset()
        XCTAssertEqual(apply("YEREE"), "YẺE")
        engine.reset()
        XCTAssertEqual(apply("YEXEE"), "YẼE")
        engine.reset()
        XCTAssertEqual(apply("YEJEE"), "YẸE")

        // 6. VNI open circumflex double-key undo on ye across tones
        vniEng.reset()
        XCTAssertEqual(apply("ye166", engine: vniEng), "yé6")
        vniEng.reset()
        XCTAssertEqual(apply("ye266", engine: vniEng), "yè6")
        vniEng.reset()
        XCTAssertEqual(apply("ye366", engine: vniEng), "yẻ6")
        vniEng.reset()
        XCTAssertEqual(apply("ye466", engine: vniEng), "yẽ6")
        vniEng.reset()
        XCTAssertEqual(apply("ye566", engine: vniEng), "yẹ6")
        vniEng.reset()
        XCTAssertEqual(apply("Ye166", engine: vniEng), "Yé6")
        vniEng.reset()
        XCTAssertEqual(apply("Ye266", engine: vniEng), "Yè6")
        vniEng.reset()
        XCTAssertEqual(apply("Ye366", engine: vniEng), "Yẻ6")
        vniEng.reset()
        XCTAssertEqual(apply("Ye466", engine: vniEng), "Yẽ6")
        vniEng.reset()
        XCTAssertEqual(apply("Ye566", engine: vniEng), "Yẹ6")
        vniEng.reset()
        XCTAssertEqual(apply("YE166", engine: vniEng), "YÉ6")
        vniEng.reset()
        XCTAssertEqual(apply("YE266", engine: vniEng), "YÈ6")
        vniEng.reset()
        XCTAssertEqual(apply("YE366", engine: vniEng), "YẺ6")
        vniEng.reset()
        XCTAssertEqual(apply("YE466", engine: vniEng), "YẼ6")
        vniEng.reset()
        XCTAssertEqual(apply("YE566", engine: vniEng), "YẸ6")

        // 7. Backspace and retyping after double-key undo on ye
        engine.reset()
        XCTAssertEqual(apply("yefee<BS>e"), "yề")
        engine.reset()
        XCTAssertEqual(apply("yeree<BS>e"), "yể")
        engine.reset()
        XCTAssertEqual(apply("yexee<BS>e"), "yễ")
        engine.reset()
        XCTAssertEqual(apply("yejee<BS>e"), "yệ")
        engine.reset()
        XCTAssertEqual(apply("Yefee<BS>e"), "Yề")
        engine.reset()
        XCTAssertEqual(apply("Yeree<BS>e"), "Yể")
        engine.reset()
        XCTAssertEqual(apply("Yexee<BS>e"), "Yễ")
        engine.reset()
        XCTAssertEqual(apply("Yejee<BS>e"), "Yệ")
        engine.reset()
        XCTAssertEqual(apply("YEFEE<BS>E"), "YỀ")

        vniEng.reset()
        XCTAssertEqual(apply("ye166<BS>6", engine: vniEng), "yế")
        vniEng.reset()
        XCTAssertEqual(apply("ye266<BS>6", engine: vniEng), "yề")
        vniEng.reset()
        XCTAssertEqual(apply("ye366<BS>6", engine: vniEng), "yể")
        vniEng.reset()
        XCTAssertEqual(apply("ye466<BS>6", engine: vniEng), "yễ")
        vniEng.reset()
        XCTAssertEqual(apply("ye566<BS>6", engine: vniEng), "yệ")
        vniEng.reset()
        XCTAssertEqual(apply("Ye166<BS>6", engine: vniEng), "Yế")
        vniEng.reset()
        XCTAssertEqual(apply("Ye266<BS>6", engine: vniEng), "Yề")
        vniEng.reset()
        XCTAssertEqual(apply("Ye366<BS>6", engine: vniEng), "Yể")
        vniEng.reset()
        XCTAssertEqual(apply("Ye466<BS>6", engine: vniEng), "Yễ")
        vniEng.reset()
        XCTAssertEqual(apply("Ye566<BS>6", engine: vniEng), "Yệ")
        vniEng.reset()
        XCTAssertEqual(apply("YE166<BS>6", engine: vniEng), "YẾ")
        vniEng.reset()
        XCTAssertEqual(apply("YE266<BS>6", engine: vniEng), "YỀ")
    }

    func test_404_untoned_diacritic_double_key_undo_and_backspace_retyping() {
        // 1. Telex circumflex (a/e/o) double-key undo on untoned syllables with codas
        engine.reset()
        XCTAssertEqual(apply("canaa"), "cana")
        engine.reset()
        XCTAssertEqual(apply("congoo"), "congo")
        engine.reset()
        XCTAssertEqual(apply("quenee"), "quene")
        engine.reset()
        XCTAssertEqual(apply("xomoo"), "xomo")
        engine.reset()
        XCTAssertEqual(apply("tienee"), "tiene")
        engine.reset()
        XCTAssertEqual(apply("uonoo"), "uono")
        engine.reset()
        XCTAssertEqual(apply("quanaa"), "quana")
        engine.reset()
        XCTAssertEqual(apply("acaa"), "aca")
        engine.reset()
        XCTAssertEqual(apply("ataa"), "ata")
        engine.reset()
        XCTAssertEqual(apply("ocoo"), "oco")
        engine.reset()
        XCTAssertEqual(apply("opoo"), "opo")
        engine.reset()
        XCTAssertEqual(apply("ecee"), "ece")
        engine.reset()
        XCTAssertEqual(apply("echee"), "eche")
        engine.reset()
        XCTAssertEqual(apply("apaa"), "apa")

        // 2. Telex breve (w) double-key undo on untoned syllables with codas
        engine.reset()
        XCTAssertEqual(apply("canww"), "canw")
        engine.reset()
        XCTAssertEqual(apply("toanww"), "toanw")
        engine.reset()
        XCTAssertEqual(apply("bangww"), "bangw")
        engine.reset()
        XCTAssertEqual(apply("thangww"), "thangw")
        engine.reset()
        XCTAssertEqual(apply("tamww"), "tamw")
        engine.reset()
        XCTAssertEqual(apply("catww"), "catw")
        engine.reset()
        XCTAssertEqual(apply("atww"), "atw")
        engine.reset()
        XCTAssertEqual(apply("acww"), "acw")
        engine.reset()
        XCTAssertEqual(apply("apww"), "apw")

        // 3. Telex horn (w) double-key undo on untoned syllables with codas and off-glides
        engine.reset()
        XCTAssertEqual(apply("conww"), "conw")
        engine.reset()
        XCTAssertEqual(apply("tungww"), "tungw")
        engine.reset()
        XCTAssertEqual(apply("munww"), "munw")
        engine.reset()
        XCTAssertEqual(apply("choiww"), "choiw")
        engine.reset()
        XCTAssertEqual(apply("cuuww"), "cuuw")
        engine.reset()
        XCTAssertEqual(apply("chuaww"), "chuaw")

        // 4. Telex delayed stroke (d) double-key undo on untoned syllables
        engine.reset()
        XCTAssertEqual(apply("didd"), "did")
        engine.reset()
        XCTAssertEqual(apply("dadd"), "dad")
        engine.reset()
        XCTAssertEqual(apply("dangdd"), "dangd")
        engine.reset()
        XCTAssertEqual(apply("dondd"), "dond")

        // 5. Telex circumflex (a/e/o) double-key undo on untoned off-glides
        engine.reset()
        XCTAssertEqual(apply("cayaa"), "caya")
        engine.reset()
        XCTAssertEqual(apply("cauaa"), "caua")
        engine.reset()
        XCTAssertEqual(apply("toioo"), "toio")
        engine.reset()
        XCTAssertEqual(apply("neuee"), "neue")
        engine.reset()
        XCTAssertEqual(apply("tieuee"), "tieue")
        engine.reset()
        XCTAssertEqual(apply("thueee"), "thuee")
        engine.reset()
        XCTAssertEqual(apply("chuoioo"), "chuoio")
        engine.reset()
        XCTAssertEqual(apply("khuayaa"), "khuaya")

        // 6. Uppercase untoned diacritic double-key undo
        engine.reset()
        XCTAssertEqual(apply("CANAA"), "CANA")
        engine.reset()
        XCTAssertEqual(apply("CONGOO"), "CONGO")
        engine.reset()
        XCTAssertEqual(apply("CANWW"), "CANW")
        engine.reset()
        XCTAssertEqual(apply("TOANWW"), "TOANW")
        engine.reset()
        XCTAssertEqual(apply("DIDD"), "DID")
        engine.reset()
        XCTAssertEqual(apply("DANGDD"), "DANGD")
        engine.reset()
        XCTAssertEqual(apply("CAYAA"), "CAYA")
        engine.reset()
        XCTAssertEqual(apply("TOIOO"), "TOIO")

        // 7. VNI untoned diacritic double-key undo
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("can66", engine: vniEng), "can6")
        vniEng.reset()
        XCTAssertEqual(apply("cong66", engine: vniEng), "cong6")
        vniEng.reset()
        XCTAssertEqual(apply("can88", engine: vniEng), "can8")
        vniEng.reset()
        XCTAssertEqual(apply("toan88", engine: vniEng), "toan8")
        vniEng.reset()
        XCTAssertEqual(apply("di99", engine: vniEng), "di9")
        vniEng.reset()
        XCTAssertEqual(apply("dang99", engine: vniEng), "dang9")
        vniEng.reset()
        XCTAssertEqual(apply("cay66", engine: vniEng), "cay6")
        vniEng.reset()
        XCTAssertEqual(apply("toi66", engine: vniEng), "toi6")
        vniEng.reset()
        XCTAssertEqual(apply("con77", engine: vniEng), "con7")
        vniEng.reset()
        XCTAssertEqual(apply("tung77", engine: vniEng), "tung7")
        vniEng.reset()
        XCTAssertEqual(apply("ac66", engine: vniEng), "ac6")
        vniEng.reset()
        XCTAssertEqual(apply("at66", engine: vniEng), "at6")
        vniEng.reset()
        XCTAssertEqual(apply("ot66", engine: vniEng), "ot6")
        vniEng.reset()
        XCTAssertEqual(apply("at88", engine: vniEng), "at8")
        vniEng.reset()
        XCTAssertEqual(apply("ac88", engine: vniEng), "ac8")

        // 8. Backspace and retyping after untoned double-key undo
        engine.reset()
        XCTAssertEqual(apply("canaa<BS>a"), "cân")
        engine.reset()
        XCTAssertEqual(apply("congoo<BS>o"), "công")
        engine.reset()
        XCTAssertEqual(apply("canww<BS>w"), "căn")
        engine.reset()
        XCTAssertEqual(apply("toanww<BS>w"), "toăn")
        engine.reset()
        XCTAssertEqual(apply("didd<BS>d"), "đi")
        engine.reset()
        XCTAssertEqual(apply("dangdd<BS>d"), "đang")
        engine.reset()
        XCTAssertEqual(apply("cayaa<BS>a"), "cây")
        engine.reset()
        XCTAssertEqual(apply("toioo<BS>o"), "tôi")
        engine.reset()
        XCTAssertEqual(apply("CANAA<BS>A"), "CÂN")
        engine.reset()
        XCTAssertEqual(apply("CONGOO<BS>O"), "CÔNG")
        engine.reset()
        XCTAssertEqual(apply("acaa<BS>a"), "âc")
        engine.reset()
        XCTAssertEqual(apply("ataa<BS>a"), "ât")
        engine.reset()
        XCTAssertEqual(apply("atww<BS>w"), "ăt")

        vniEng.reset()
        XCTAssertEqual(apply("can66<BS>6", engine: vniEng), "cân")
        vniEng.reset()
        XCTAssertEqual(apply("can88<BS>8", engine: vniEng), "căn")
        vniEng.reset()
        XCTAssertEqual(apply("di99<BS>9", engine: vniEng), "đi")
        vniEng.reset()
        XCTAssertEqual(apply("dang99<BS>9", engine: vniEng), "đang")
        vniEng.reset()
        XCTAssertEqual(apply("ac66<BS>6", engine: vniEng), "âc")
        vniEng.reset()
        XCTAssertEqual(apply("at88<BS>8", engine: vniEng), "ăt")
    }

    func test_405_heje_and_he_thong_fast_typing_and_backspace() {
        // 1. Standalone "heje" vs "heej" and casing variants
        engine.reset()
        XCTAssertEqual(apply("heje"), "hệ")
        engine.reset()
        XCTAssertEqual(apply("heej"), "hệ")
        engine.reset()
        XCTAssertEqual(apply("Heje"), "Hệ")
        engine.reset()
        XCTAssertEqual(apply("HEJE"), "HỆ")
        engine.reset()
        XCTAssertEqual(apply("heje "), "hệ ")
        engine.reset()
        XCTAssertEqual(apply("heje."), "hệ.")

        // 2. Fast-typing "hệ thống" and common "hệ" compounds
        engine.reset()
        XCTAssertEqual(apply("heje thoongs"), "hệ thống")
        engine.reset()
        XCTAssertEqual(apply("heje thongos"), "hệ thống")
        engine.reset()
        XCTAssertEqual(apply("heje thosngo"), "hệ thống")
        engine.reset()
        XCTAssertEqual(apply("heje thoosng"), "hệ thống")
        engine.reset()
        XCTAssertEqual(apply("heje thosong"), "hệ thống")
        engine.reset()
        XCTAssertEqual(apply("heje thoonsg"), "hệ thống")
        engine.reset()
        XCTAssertEqual(apply("heje thonogs"), "hệ thống")
        engine.reset()
        XCTAssertEqual(apply("heje thongso"), "hệ thống")
        engine.reset()
        XCTAssertEqual(apply("Heje thoongs"), "Hệ thống")
        engine.reset()
        XCTAssertEqual(apply("HEJE THOONGS"), "HỆ THỐNG")
        engine.reset()
        XCTAssertEqual(apply("heje quar"), "hệ quả")
        engine.reset()
        XCTAssertEqual(apply("heje soso"), "hệ số")
        engine.reset()
        XCTAssertEqual(apply("lieen heje"), "liên hệ")
        engine.reset()
        XCTAssertEqual(apply("quan heje"), "quan hệ")
        engine.reset()
        XCTAssertEqual(apply("thees heje"), "thế hệ")

        // 3. Sentences, punctuation boundaries, post-"tệ" immediate conversion, and retrospective healing
        engine.reset()
        XCTAssertEqual(apply("xaay duwngj heje thoongs"), "xây dựng hệ thống")
        engine.reset()
        XCTAssertEqual(apply("tooif teje. heje"), "tồi tệ. hệ")
        engine.reset()
        XCTAssertEqual(apply("tooif teje heje"), "tồi tệ hệ")
        engine.reset()
        XCTAssertEqual(apply("quas teje heje"), "quá tệ hệ")
        engine.reset()
        XCTAssertEqual(apply("tieenf teje heje"), "tiền tệ hệ")
        engine.reset()
        XCTAssertEqual(apply("tooif teje heje thoongs"), "tồi tệ hệ thống")
        engine.reset()
        XCTAssertEqual(apply("tooif teje heje soso"), "tồi tệ hệ số")
        engine.reset()
        XCTAssertEqual(apply("tooif teje heje khachs"), "tồi tệ hệ khách")
        engine.reset()
        XCTAssertEqual(apply("neje heje thoongs"), "neje hệ thống")
        engine.reset()
        XCTAssertEqual(apply("neje heje soso"), "neje hệ số")

        // 4. Double-key undo and backspace recovery (including spaceHistory boundary restoration)
        engine.reset()
        XCTAssertEqual(apply("hejee"), "hẹe")
        engine.reset()
        XCTAssertEqual(apply("hejee<BS>e"), "hệ")
        engine.reset()
        XCTAssertEqual(apply("heje<BS>eje"), "hệ")
        engine.reset()
        XCTAssertEqual(apply("heje thoongs<BS><BS><BS><BS><BS>quar"), "hệ quả")
        engine.reset()
        XCTAssertEqual(apply("neje, foo <BS><BS><BS><BS>heje"), "neje, hệ")

        // 5. VNI mode
        let vniEng = makeEngine(inputMethod: .vni, tonePlacement: .modern)
        XCTAssertEqual(apply("he56", engine: vniEng), "hệ")
        vniEng.reset()
        XCTAssertEqual(apply("he65", engine: vniEng), "hệ")
        vniEng.reset()
        XCTAssertEqual(apply("he56 tho6ng1", engine: vniEng), "hệ thống")
    }

    func test_406_double_key_tone_escape_for_test_and_english_coda_clusters() {
        // 1. Core 'test' family typed with double 's' (tesst, tessts, tesster, tessted, tessting) and casing
        let testCases: [(String, String)] = [
            ("tesst", "test"),
            ("tessts", "tests"),
            ("tesster", "tester"),
            ("tessters", "testers"),
            ("tessted", "tested"),
            ("tessting", "testing"),
            ("Tesst", "Test"),
            ("TESST", "TEST"),
            ("Tessting", "Testing"),
            // 2. Other -st words typed with double 's'
            ("besst", "best"),
            ("resst", "rest"),
            ("wesst", "west"),
            ("nesst", "nest"),
            ("pesst", "pest"),
            ("vesst", "vest"),
            ("chesst", "chest"),
            ("guesst", "guest"),
            ("quesst", "quest"),
            ("requesst", "request"),
            ("latesst", "latest"),
            ("fasst", "fast"),
            ("lasst", "last"),
            ("masst", "mast"),
            ("passt", "past"),
            ("casst", "cast"),
            ("vasst", "vast"),
            ("lisst", "list"),
            ("misst", "mist"),
            ("fisst", "fist"),
            ("cosst", "cost"),
            ("mosst", "most"),
            ("losst", "lost"),
            ("hosst", "host"),
            ("posst", "post"),
            ("dusst", "dust"),
            ("russt", "rust"),
            ("musst", "must"),
            ("jusst", "just"),
            ("busst", "bust"),
            ("trusst", "trust"),
            ("firsst", "first"),
            ("bursst", "burst"),
            ("harvesst", "harvest"),
            ("foresst", "forest"),
            ("manifesst", "manifest"),
            ("minibeassts", "minibeasts"),
            ("honesst", "honest"),
            ("modesst", "modest"),
            ("detesst", "detest"),
            ("protesst", "protest"),
            ("contesst", "contest"),
            ("invesst", "invest"),
            ("suggesst", "suggest"),
            ("digesst", "digest"),
            ("assisst", "assist"),
            // 3. -sk, -sp, -sc words typed with double 's', while preserving pass* compounds and ss+vowel words
            ("tassk", "task"),
            ("tassks", "tasks"),
            ("massk", "mask"),
            ("assk", "ask"),
            ("dessk", "desk"),
            ("rissk", "risk"),
            ("dissk", "disk"),
            ("dussk", "dusk"),
            ("gassp", "gasp"),
            ("rassp", "rasp"),
            ("lissp", "lisp"),
            ("cussp", "cusp"),
            ("classp", "clasp"),
            ("grassp", "grasp"),
            ("crissp", "crisp"),
            ("dissc", "disc"),
            ("disscs", "discs"),
            ("passcode", "passcode"),
            ("passport", "passport"),
            ("passkey", "passkey"),
            ("password", "password"),
            ("Passcode", "Passcode"),
            ("Passport", "Passport"),
            ("Passkey", "Passkey"),
            ("Crosspost", "Crosspost"),
            ("crosscheck", "crosscheck"),
            ("crosstalk", "crosstalk"),
            ("misstep", "misstep"),
            ("misstate", "misstate"),
            ("misspell", "misspell"),
            ("classpath", "classpath"),
            ("guesstimate", "guesstimate"),
            ("offtrack", "offtrack"),
            ("session", "session"),
            ("message", "message"),
            ("lesson", "lesson"),
            // 4. Multi-syllable words where the first syllable has a Vietnamese diacritic before splitting
            ("domesstic", "domestic"),
            ("domesstics", "domestics"),
            ("tootesst", "tootest"),
            ("deetesst", "deetest"),
            ("darrkness", "darkness"),
            // 5. -ft and -rt/-rd/-rm/-rk words typed with double 'f' / double 'r'
            ("lefft", "left"),
            ("lifft", "lift"),
            ("gifft", "gift"),
            ("shifft", "shift"),
            ("swifft", "swift"),
            ("drifft", "drift"),
            ("sofft", "soft"),
            ("lofft", "loft"),
            ("crafft", "craft"),
            ("drafft", "draft"),
            ("tarrt", "tart"),
            ("carrd", "card"),
            ("sorrt", "sort"),
            ("terrm", "term"),
            ("darrk", "dark"),
            ("borrn", "born"),
            ("offset", "offset"),
            ("offline", "offline"),
            ("carry", "carry"),
            ("sorry", "sorry"),
            ("style.csst", "style.csst"),
        ]
        for (raw, expected) in testCases {
            engine.reset()
            XCTAssertEqual(apply(raw), expected, "Failed for input: \(raw)")
        }

        // 6. Backspace and mixed Vietnamese-English sentence flows
        engine.reset()
        XCTAssertEqual(apply("tesst<BS>t"), "test")
        engine.reset()
        XCTAssertEqual(apply("wesst<BS>t"), "west")
        engine.reset()
        XCTAssertEqual(apply("lasst<BS>s"), "lass")
        engine.reset()
        XCTAssertEqual(apply("tesste<BS>ed"), "tested")
        engine.reset()
        XCTAssertEqual(apply("tessted<BS>r"), "tester")
        engine.reset()
        XCTAssertEqual(apply("tesst<BS><BS>s"), "té")
        engine.reset()
        XCTAssertEqual(apply("tooi ddang tesst heej thoongs vaf latesst tassk"), "tôi đang test hệ thống và latest task")

        // 7. SimpleTelex mode
        let simpleEng = makeEngine(inputMethod: .simpleTelex, tonePlacement: .modern)
        XCTAssertEqual(apply("tesst", engine: simpleEng), "test")
        simpleEng.reset()
        XCTAssertEqual(apply("tessting", engine: simpleEng), "testing")
        simpleEng.reset()
        XCTAssertEqual(apply("domesstic", engine: simpleEng), "domestic")
    }

    func test_407_barn_to_ban_telex_and_backspace_recovery() {
        // 1. Standalone 'barn' and 'banr' permutations, casing, and punctuation boundaries
        let standaloneCases: [(String, String)] = [
            ("barn", "bản"),
            ("banr", "bản"),
            ("Barn", "Bản"),
            ("BARN", "BẢN"),
            ("barn ", "bản "),
            ("barn.", "bản."),
            ("barn,", "bản,"),
            ("(barn)", "(bản)"),
            // 2. Vietnamese compounds and phrases starting or ending with 'bản', including 'bản cơ...' / 'bản cờ'
            ("barn ddoof", "bản đồ"),
            ("barn thaan", "bản thân"),
            ("barn chaats", "bản chất"),
            ("barn sao", "bản sao"),
            ("barn tin", "bản tin"),
            ("barn nhacj", "bản nhạc"),
            ("barn ans", "bản án"),
            ("barn aasn", "bản ấn"),
            ("barn quyenef", "bản quyền"),
            ("barn cow", "bản cơ"),
            ("barn cow barn", "bản cơ bản"),
            ("barn cow sowr", "bản cơ sở"),
            ("barn cowf", "bản cờ"),
            ("barn cows", "bản cớ"),
            ("barn cowr", "bản cở"),
            ("barn cowx", "bản cỡ"),
            ("barn cowj", "bản cợ"),
            ("barn cowm", "bản cơm"),
            ("barn cown", "bản cơn"),
            ("cow barn", "cơ bản"),
            ("vawn barn", "văn bản"),
            ("phieen barn", "phiên bản"),
            ("kijch barn", "kịch bản"),
            ("nguyeen barn", "nguyên bản"),
            ("xuaats barn", "xuất bản"),
            // 3. Continuations from 'barn' ('bản') and English derivatives starting with 'barn'
            ("barng", "bảng"),
            ("barnh", "bảnh"),
            ("barnw", "bẳn"),
            ("barngw", "bẳng"),
            ("barna", "bẩn"),
            ("barnga", "bẩng"),
            ("barnf", "bàn"),
            ("barnj", "bạn"),
            ("barnx", "bãn"),
            ("barns", "barns"),
            ("mua barns", "mua bán"),
            ("barnacle", "barnacle"),
            ("barnyard", "barnyard"),
            ("barnstorm", "barnstorm"),
            ("barndoor", "barndoor"),
            ("barnet", "barnet"),
            // 4. Double-key tone undo for English 'barn' (standalone and after technical separators)
            ("barnr", "barn"),
            ("barrn", "barn"),
            ("Barnr", "Barn"),
            ("Barrn", "Barn"),
            ("BARNR", "BARN"),
            ("BARRN", "BARN"),
            ("foo-barnr", "foo-barn"),
            ("foo/barnr", "foo/barn"),
            ("foo_barnr", "foo_barn"),
            ("foo.barnr", "foo.barn"),
            ("foo-barrn", "foo-barn"),
        ]
        for (raw, expected) in standaloneCases {
            engine.reset()
            XCTAssertEqual(apply(raw), expected, "Failed for input: \(raw)")
        }

        // 5. Backspace recovery (within-word and across word boundary after retrospective restoration)
        engine.reset()
        XCTAssertEqual(apply("barn<BS>n"), "bản")
        engine.reset()
        XCTAssertEqual(apply("barn<BS>ng"), "bảng")
        engine.reset()
        XCTAssertEqual(apply("barnr<BS>"), "bar")
        engine.reset()
        XCTAssertEqual(apply("barnr<BS>n"), "barn")
        engine.reset()
        XCTAssertEqual(apply("barnr<BS><BS>rn"), "bản")
        engine.reset()
        XCTAssertEqual(apply("barrn<BS>"), "bar")
        engine.reset()
        XCTAssertEqual(apply("barrn<BS>n"), "barn")
        engine.reset()
        XCTAssertEqual(apply("barrn<BS><BS>rn"), "bản")
        engine.reset()
        XCTAssertEqual(apply("barn barnh<BS><BS><BS><BS><BS>n"), "bản")

        // 6. SimpleTelex mode
        let simpleEng = makeEngine(inputMethod: .simpleTelex, tonePlacement: .modern)
        XCTAssertEqual(apply("barn", engine: simpleEng), "bản")
        simpleEng.reset()
        XCTAssertEqual(apply("barn ddoof", engine: simpleEng), "bản đồ")
        simpleEng.reset()
        XCTAssertEqual(apply("barnr", engine: simpleEng), "barn")
        simpleEng.reset()
        XCTAssertEqual(apply("barrn", engine: simpleEng), "barn")
    }

    // MARK: - Test Registry (407 Tests)
    
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

            // Section 19: Long-Essay & Code Review Batch 1 (15 tests)
            ("test_356_gi_early_tone_before_shorthand_w", test_356_gi_early_tone_before_shorthand_w),
            ("test_357_multi_syllable_english_auto_restore_er_or_en", test_357_multi_syllable_english_auto_restore_er_or_en),
            ("test_358_multi_syllable_english_auto_restore_first_syllable_tone", test_358_multi_syllable_english_auto_restore_first_syllable_tone),
            ("test_359_multi_syllable_english_auto_restore_diacritic_suffix", test_359_multi_syllable_english_auto_restore_diacritic_suffix),
            ("test_360_double_press_undo_vs_non_adjacent_absorption", test_360_double_press_undo_vs_non_adjacent_absorption),
            ("test_361_long_essay_literature_ha_noi_mua_thu_full", test_361_long_essay_literature_ha_noi_mua_thu_full),
            ("test_362_long_essay_literature_with_heavy_backspace_edits", test_362_long_essay_literature_with_heavy_backspace_edits),
            ("test_363_long_essay_software_engineering_and_devops", test_363_long_essay_software_engineering_and_devops),
            ("test_364_long_essay_software_engineering_with_backspace_edits", test_364_long_essay_software_engineering_with_backspace_edits),
            ("test_365_long_essay_journalism_economy_and_society", test_365_long_essay_journalism_economy_and_society),
            ("test_366_long_essay_journalism_with_backspace_edits", test_366_long_essay_journalism_with_backspace_edits),
            ("test_367_long_dialogue_multiline_conversation", test_367_long_dialogue_multiline_conversation),
            ("test_368_long_essay_vni_mixed_orders_and_numbers", test_368_long_essay_vni_mixed_orders_and_numbers),
            ("test_369_long_essay_traditional_tone_style", test_369_long_essay_traditional_tone_style),
            ("test_370_long_essay_simple_telex_mode", test_370_long_essay_simple_telex_mode),

            // Section 20: Long-Essay & Code Review Batch 2 (15 tests)
            ("test_371_howacj_xowans_khowan_early_w_after_o_before_a", test_371_howacj_xowans_khowan_early_w_after_o_before_a),
            ("test_372_single_syllable_english_invalid_coda_auto_restore", test_372_single_syllable_english_invalid_coda_auto_restore),
            ("test_373_double_vowel_english_invalid_coda_auto_restore", test_373_double_vowel_english_invalid_coda_auto_restore),
            ("test_374_english_coda_k_and_b_and_f_auto_restore", test_374_english_coda_k_and_b_and_f_auto_restore),
            ("test_375_dak_lak_valid_vietnamese_coda_k_preserved", test_375_dak_lak_valid_vietnamese_coda_k_preserved),
            ("test_376_long_essay_history_and_culture_viet_nam", test_376_long_essay_history_and_culture_viet_nam),
            ("test_377_long_essay_history_and_culture_with_heavy_backspace", test_377_long_essay_history_and_culture_with_heavy_backspace),
            ("test_378_long_essay_fullstack_engineering_code_switching", test_378_long_essay_fullstack_engineering_code_switching),
            ("test_379_long_essay_fullstack_engineering_with_backspace", test_379_long_essay_fullstack_engineering_with_backspace),
            ("test_380_long_essay_parentheses_brackets_quotes_urls_emails", test_380_long_essay_parentheses_brackets_quotes_urls_emails),
            ("test_381_long_essay_uppercase_headings_and_mixed_case", test_381_long_essay_uppercase_headings_and_mixed_case),
            ("test_382_long_essay_scientific_medicine_and_environment", test_382_long_essay_scientific_medicine_and_environment),
            ("test_383_long_essay_scientific_with_heavy_backspace", test_383_long_essay_scientific_with_heavy_backspace),
            ("test_384_long_essay_vni_complex_mixed_english_and_numbers", test_384_long_essay_vni_complex_mixed_english_and_numbers),
            ("test_385_stress_test_delete_entire_paragraph_and_retype", test_385_stress_test_delete_entire_paragraph_and_retype),

            // Section 21: Regression Coverage for Backspace and Duplicate Coda (6 tests)
            ("test_386_backspace_deleted_g_then_type_n_preserves_ascii_and_recovers_vietnamese_ng", test_386_backspace_deleted_g_then_type_n_preserves_ascii_and_recovers_vietnamese_ng),
            ("test_387_duplicate_coda_consonant_suppression_on_vietnamese_syllables", test_387_duplicate_coda_consonant_suppression_on_vietnamese_syllables),
            ("test_388_ascii_control_characters_reset_engine_buffer", test_388_ascii_control_characters_reset_engine_buffer),
            ("test_389_backspace_across_technical_separator_restores_active_syllable", test_389_backspace_across_technical_separator_restores_active_syllable),
            ("test_390_deep_backspace_across_technical_separators_and_mixed_bypass", test_390_deep_backspace_across_technical_separators_and_mixed_bypass),
            ("test_391_backspace_across_compound_words_2_and_3_syllables", test_391_backspace_across_compound_words_2_and_3_syllables),

            // Section 22: Backspace Across Punctuation / Delimiters & Double-Tone / Double-Diacritic Undo Recovery (4 tests)
            ("test_392_backspace_across_punctuation_and_bracket_boundaries", test_392_backspace_across_punctuation_and_bracket_boundaries),
            ("test_393_double_tone_undo_followed_by_backspace_and_retyping", test_393_double_tone_undo_followed_by_backspace_and_retyping),
            ("test_394_double_diacritic_undo_followed_by_backspace_and_retyping", test_394_double_diacritic_undo_followed_by_backspace_and_retyping),
            ("test_395_compound_word_boundary_double_consonants_and_collocation_backspace_recovery", test_395_compound_word_boundary_double_consonants_and_collocation_backspace_recovery),
            ("test_396_delayed_diacritic_double_key_undo_and_backspace_retyping", test_396_delayed_diacritic_double_key_undo_and_backspace_retyping),
            ("test_397_uppercase_toned_diacritic_double_key_undo_and_backspace_retyping", test_397_uppercase_toned_diacritic_double_key_undo_and_backspace_retyping),
            ("test_398_toned_dual_horn_diacritic_double_key_undo_and_backspace_retyping", test_398_toned_dual_horn_diacritic_double_key_undo_and_backspace_retyping),
            ("test_399_coda_and_offglide_dual_horn_diacritic_double_key_undo_and_backspace_retyping", test_399_coda_and_offglide_dual_horn_diacritic_double_key_undo_and_backspace_retyping),
            ("test_400_circumflex_breve_stroke_diacritic_double_key_undo_with_codas_and_tones", test_400_circumflex_breve_stroke_diacritic_double_key_undo_with_codas_and_tones),
            ("test_401_offglide_diphthong_circumflex_and_untoned_stroke_diacritic_double_key_undo", test_401_offglide_diphthong_circumflex_and_untoned_stroke_diacritic_double_key_undo),
            ("test_402_open_diphthong_circumflex_double_key_undo_and_backspace_retyping", test_402_open_diphthong_circumflex_double_key_undo_and_backspace_retyping),
            ("test_403_onglide_ye_tone_placement_and_circumflex_double_key_undo", test_403_onglide_ye_tone_placement_and_circumflex_double_key_undo),
            ("test_404_untoned_diacritic_double_key_undo_and_backspace_retyping", test_404_untoned_diacritic_double_key_undo_and_backspace_retyping),
            ("test_405_heje_and_he_thong_fast_typing_and_backspace", test_405_heje_and_he_thong_fast_typing_and_backspace),
            ("test_406_double_key_tone_escape_for_test_and_english_coda_clusters", test_406_double_key_tone_escape_for_test_and_english_coda_clusters),
            ("test_407_barn_to_ban_telex_and_backspace_recovery", test_407_barn_to_ban_telex_and_backspace_recovery),
        ]
    }
}
