//
//  GoTests.swift
//  GoTests
//
//  Created by Jae Seung Lee on 8/4/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import XCTest
@testable import Go

class GoTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSGFParseSingleGame() throws {
        let sgfString = "(;FF[1]SZ[19]PB[Player]PW[COMLv10]BS[0]WS[10]KM[6.5]HA[0]RU[JP]AP[Champ Go HD]VW[]GN[Champ Go HD]GC[]DT[2020-12-31 09:44:05]RE[B+R];B[pq]TL[0,0];W[dp]TL[0,0];B[pd]TL[1,0];W[dc]TL[0,0];B[ce]TL[2,0];W[dh]TL[0,0];B[ed]TL[2,0];W[ec]TL[0,0];B[fd]TL[1,0];W[gc]TL[0,0];B[he]TL[0,0];W[cd]TL[0,0];B[be]TL[2,0];W[ef]TL[0,0];B[de]TL[2,0];W[hc]TL[0,0];B[ci]TL[2,0];W[ch]TL[0,0];B[bh]TL[0,0];W[bg]TL[0,0];B[bj]TL[0,0];W[ah]TL[0,0];B[bi]TL[1,0];W[ej]TL[0,0];B[cm]TL[3,0];W[em]TL[0,0];B[bp]TL[1,0];W[cq]TL[0,0];B[di]TL[6,0];W[ei]TL[0,0];B[eh]TL[0,0];W[fh]TL[0,0];B[eg]TL[0,0];W[dg]TL[0,0];B[fg]TL[0,0];W[gg]TL[0,0];B[ff]TL[0,0];W[gf]TL[0,0];B[fe]TL[2,0];W[ge]TL[0,0];B[gd]TL[5,0];W[hd]TL[0,0];B[gh]TL[0,0];W[fi]TL[0,0];B[hg]TL[0,0];W[gi]TL[0,0];B[hh]TL[1,0];W[ij]TL[0,0];B[jp]TL[25,0];W[hp]TL[0,0];B[fo]TL[29,0];W[fp]TL[0,0];B[do]TL[2,0];W[eo]TL[0,0];B[en]TL[0,0];W[ep]TL[0,0];B[fn]TL[0,0];W[dn]TL[0,0];B[dm]TL[1,0];W[co]TL[0,0];B[bo]TL[3,0];W[bq]TL[0,0];B[fl]TL[2,0];W[el]TL[0,0];B[fm]TL[2,0];W[nc]TL[0,0];B[ld]TL[9,0];W[ne]TL[0,0];B[pf]TL[0,0];W[pb]TL[0,0];B[qc]TL[0,0];W[qh]TL[0,0];B[qj]TL[2,0];W[oh]TL[0,0];B[qb]TL[4,0];W[po]TL[0,0];B[qo]TL[2,0];W[qn]TL[0,0];B[qp]TL[0,0];W[pn]TL[0,0];B[nq]TL[1,0];W[jq]TL[0,0];B[kq]TL[1,0];W[iq]TL[0,0];B[kr]TL[0,0];W[kp]TL[0,0];B[jo]TL[2,0];W[lp]TL[0,0];B[mr]TL[1,0];W[kn]TL[0,0];B[jn]TL[2,0];W[km]TL[0,0];B[jm]TL[0,0];W[kl]TL[0,0];B[jl]TL[0,0];W[kk]TL[0,0];B[jk]TL[0,0];W[jj]TL[0,0];B[kj]TL[2,0];W[ki]TL[0,0];B[lj]TL[0,0];W[li]TL[0,0];B[mj]TL[0,0];W[ni]TL[0,0];B[ko]TL[2,0];W[lo]TL[0,0];B[ln]TL[0,0];W[mm]TL[0,0];B[mn]TL[1,0];W[nn]TL[0,0];B[mo]TL[0,0];W[mp]TL[0,0];B[no]TL[0,0];W[np]TL[0,0];B[nm]TL[2,0];W[ml]TL[0,0];B[oo]TL[7,0];W[op]TL[0,0];B[on]TL[0,0];W[ol]TL[0,0];B[om]TL[60,0];W[pm]TL[0,0];B[nl]TL[1,0];W[nk]TL[0,0];B[ok]TL[8,0];W[pl]TL[0,0];B[mk]TL[0,0];W[nj]TL[0,0];B[ll]TL[2,0];W[mi]TL[0,0];B[lm]TL[1,0];W[pp]TL[0,0];B[qr]TL[1,0];W[oq]TL[0,0];B[or]TL[0,0];W[lb]TL[0,0];B[ie]TL[7,0];W[jd]TL[0,0];B[je]TL[1,0];W[rf]TL[0,0];B[qe]TL[1,0];W[re]TL[0,0];B[rd]TL[0,0];W[pc]TL[0,0];B[oe]TL[2,0];W[od]TL[0,0];B[nf]TL[1,0];W[me]TL[0,0];B[qf]TL[1,0];W[rg]TL[0,0];B[pa]TL[1,0];W[dl]TL[0,0];B[cl]TL[1,0];W[hn]TL[0,0];B[hm]TL[1,0];W[mf]TL[0,0];B[ng]TL[1,0];W[ke]TL[0,0];B[bc]TL[7,0];W[fk]TL[0,0];B[hk]TL[6,0];W[hi]TL[0,0];B[jh]TL[1,0];W[ji]TL[0,0];B[fc]TL[3,0];W[fb]TL[0,0];B[id]TL[0,0];W[ic]TL[0,0];B[jc]TL[1,0];W[kd]TL[0,0];B[gb]TL[1,0];W[hb]TL[0,0];B[eb]TL[1,0];W[ga]TL[0,0];B[db]TL[0,0];W[bn]TL[0,0];B[cn]TL[1,0];W[oa]TL[0,0];B[qa]TL[2,0];W[nb]TL[0,0];B[pi]TL[30,0];W[og]TL[0,0];B[of]TL[1,0];W[qk]TL[0,0];B[pk]TL[1,0];W[rk]TL[0,0];B[rj]TL[1,0];W[rn]TL[0,0];B[ro]TL[0,0];W[so]TL[0,0];B[sp]TL[0,0];W[sn]TL[0,0];B[rq]TL[0,0];W[gk]TL[0,0];B[hl]TL[1,0];W[ik]TL[0,0];B[dk]TL[4,0];W[ek]TL[0,0];B[dj]TL[0,0];W[ih]TL[0,0];B[ig]TL[1,0];W[kh]TL[0,0];B[jg]TL[1,0];W[mg]TL[0,0];B[nh]TL[1,0];W[qg]TL[0,0];B[oi]TL[2,0];W[sd]TL[0,0];B[sc]TL[1,0];W[se]TL[0,0];B[rl]TL[2,0];W[ql]TL[0,0];B[sk]TL[1,0];W[oj]TL[0,0];B[pj]TL[0,0];W[ri]TL[0,0];B[hs]TL[3,0];W[hr]TL[0,0];B[js]TL[0,0];W[gs]TL[0,0];B[is]TL[0,0];W[mq]TL[0,0];B[nr]TL[0,0];W[kg]TL[0,0];B[kf]TL[6,0];W[lf]TL[0,0];B[jf]TL[0,0];W[gr]TL[0,0];B[lq]TL[1,0];W[il]TL[0,0];B[im]TL[1,0];W[rm]TL[0,0];B[sl]TL[2,0];W[si]TL[0,0];B[bm]TL[11,0])"
        
        let parser = SGFParser(sgfString)
    
        do {
            try parser.parse()
        } catch {
            print("Failed parsing sgfString: \(error)")
        }
        
        print("parser.gameTrees = \(parser.gameTrees)")
    }

    func testSGFParseVariation() throws {
        let sgfString = "       (;GM [1]US[someone]CoPyright[\\ Permission to reproduce this game is given.]GN[a-b]EV[None]RE[B+Resign]PW[a]WR[2k*]PB[b]BR[4k*]PC[somewhere]DT[2000-01-16]SZ[19]TM[300]KM[4.5]HA[3]AB[pd][dp][dd];W[pp];B[nq];W[oq]C[ x started observation.](;B[qc]C[ [b\\]: \\\\ hi x! ;-) \\];W[kc])(;B[hc];W[oe]))   "
        
        let parser = SGFParser(sgfString)
    
        do {
            try parser.parse()
        } catch {
            print("Failed parsing sgfString: \(error)")
        }
        
        print("parser.gameTrees = \(parser.gameTrees)")
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
