From iris.base_logic Require Export invariants gen_heap.
From iris.program_logic Require Export weakestpre ectx_lifting.
From iris.proofmode Require Import proofmode.
From iris.algebra Require Import frac.
From cap_machine Require Export rules_base.

Section cap_lang_rules.
  Context `{memG Σ, regG Σ}.
  Context `{MachineParameters}.
  Implicit Types P Q : iProp Σ.
  Implicit Types σ : ExecConf.
  Implicit Types c : cap_lang.expr.
  Implicit Types a b : Addr.
  Implicit Types r : RegName.
  Implicit Types v : cap_lang.val.
  Implicit Types w : Word.
  Implicit Types reg : gmap RegName Word.
  Implicit Types ms : gmap Addr Word.

  Inductive GetSealed_spec (regs: Reg) (dst src: RegName) (regs': Reg): cap_lang.val -> Prop :=
  | GetSealed_spec_success (w: Word):
      regs !! src = Some w →
      incrementPC (<[ dst := WInt (if is_sealed w then 1%Z else 0%Z) ]> regs) = Some regs' ->
      GetSealed_spec regs dst src regs' NextIV
  | GetSealed_spec_failure (w: Word):
      regs !! src = Some w →
      incrementPC (<[ dst := WInt (if is_sealed w then 1%Z else 0%Z) ]> regs) = None ->
      GetSealed_spec regs dst src regs' FailedV.

  Lemma wp_GetSealed Ep pc_p pc_b pc_e pc_a w dst src regs :
    decodeInstrW w = GetSealed dst src ->
    isCorrectPC (WCap pc_p pc_b pc_e pc_a) →
    regs !! PC = Some (WCap pc_p pc_b pc_e pc_a) →
    regs_of (GetSealed dst src) ⊆ dom regs →

    {{{ ▷ pc_a ↦ₐ w ∗
        ▷ [∗ map] k↦y ∈ regs, k ↦ᵣ y }}}
      Instr Executable @ Ep
    {{{ regs' retv, RET retv;
        ⌜ GetSealed_spec regs dst src regs' retv ⌝ ∗
          pc_a ↦ₐ w ∗
          [∗ map] k↦y ∈ regs', k ↦ᵣ y }}}.
  Proof.
    iIntros (Hinstr Hvpc HPC Dregs φ) "(>Hpc_a & >Hmap) Hφ".
    iApply wp_lift_atomic_head_step_no_fork; auto.
    iIntros (σ1 ns l1 l2 nt) "Hσ1 /=". destruct σ1; simpl.
    iDestruct "Hσ1" as "[Hr Hm]".
    iDestruct (gen_heap_valid_inclSepM with "Hr Hmap") as %Hregs.
    have ? := lookup_weaken _ _ _ _ HPC Hregs.
    iDestruct (@gen_heap_valid with "Hm Hpc_a") as %Hpc_a; auto.
    iModIntro. iSplitR. by iPureIntro; apply normal_always_head_reducible.
    iNext. iIntros (e2 σ2 efs Hpstep).
    apply prim_step_exec_inv in Hpstep as (-> & -> & (c & -> & Hstep)).
    iIntros "_".
    iSplitR; auto. eapply step_exec_inv in Hstep; eauto.
    rewrite /exec in Hstep.

    specialize (indom_regs_incl _ _ _ Dregs Hregs) as Hri. unfold regs_of in Hri.
    destruct (Hri dst) as [wdst [H'dst Hdst]]. by set_solver+.
    destruct (Hri src) as [wsrc [H'src Hsrc]]. by set_solver+.

    assert (exec_opt (GetSealed dst src) (r, m) = updatePC (update_reg (r, m) dst (WInt (if is_sealed wsrc then 1%Z else 0%Z)))) as HH.
    {  rewrite /= Hsrc. unfold is_sealed ; destruct_word wsrc;auto. }
    rewrite HH in Hstep. rewrite /update_reg /= in Hstep.

    destruct (incrementPC (<[ dst := WInt (if is_sealed wsrc then 1%Z else 0%Z) ]> regs))
      as [regs'|] eqn:Hregs'; pose proof Hregs' as H'regs'; cycle 1.
    { apply incrementPC_fail_updatePC with (m:=m) in Hregs'.
      eapply updatePC_fail_incl with (m':=m) in Hregs'.
      2: by apply lookup_insert_is_Some'; eauto.
      2: by apply insert_mono; eauto.
      simplify_pair_eq.
      rewrite Hregs' in Hstep. inversion Hstep.
      iFrame. iApply "Hφ"; iFrame. iPureIntro. econstructor; eauto. }

    (* Success *)

    eapply (incrementPC_success_updatePC _ m) in Hregs'
      as (p' & g' & b' & e' & a'' & a_pc' & HPC'' & HuPC & ->).
    eapply updatePC_success_incl with (m':=m) in HuPC. 2: by eapply insert_mono; eauto. rewrite HuPC in Hstep.

    simplify_pair_eq. iFrame.
    iMod ((gen_heap_update_inSepM _ _ dst) with "Hr Hmap") as "[Hr Hmap]"; eauto.
    iMod ((gen_heap_update_inSepM _ _ PC) with "Hr Hmap") as "[Hr Hmap]"; eauto.
    iFrame. iModIntro. iApply "Hφ". iFrame. iPureIntro. econstructor; eauto.
  Qed.

  Lemma wp_GetSealed_successPC E pc_p pc_b pc_e pc_a pc_a' w dst w' :
    decodeInstrW w = GetSealed dst PC →
    isCorrectPC (WCap pc_p pc_b pc_e pc_a) →
    (pc_a + 1)%a = Some pc_a' →

    {{{ ▷ PC ↦ᵣ WCap pc_p pc_b pc_e pc_a
        ∗ ▷ pc_a ↦ₐ w
        ∗ ▷ dst ↦ᵣ w'
    }}}
      Instr Executable @ E
      {{{ RET NextIV;
          PC ↦ᵣ WCap pc_p pc_b pc_e pc_a'
          ∗ pc_a ↦ₐ w
          ∗ dst ↦ᵣ WInt 0%Z }}}.
   Proof.
     iIntros (Hinstr Hvpc Hpca' ϕ) "(>HPC & >Hpc_a & >Hdst) Hφ".
     iDestruct (map_of_regs_2 with "HPC Hdst") as "[Hmap %]".
     iApply (wp_GetSealed with "[$Hmap Hpc_a]"); eauto; simplify_map_eq; eauto.
     by rewrite !dom_insert; set_solver+.
     iNext. iIntros (regs' retv) "(#Hspec & Hpc_a & Hmap)". iDestruct "Hspec" as %Hspec.

     destruct Hspec as [|].
     { iApply "Hφ". iFrame. incrementPC_inv; simplify_map_eq.
       rewrite (insert_commute _ PC dst) // insert_insert insert_commute // insert_insert.
       iDestruct (regs_of_map_2 with "Hmap") as "(?&?)"; eauto; iFrame. }
     { incrementPC_inv; simplify_map_eq; eauto. congruence. }
   Qed.

   Lemma wp_GetSealed_success E pc_p pc_b pc_e pc_a pc_a' w dst r wr w' :
     decodeInstrW w = GetSealed dst r →
     isCorrectPC (WCap pc_p pc_b pc_e pc_a) →
     (pc_a + 1)%a = Some pc_a' →

       {{{ ▷ PC ↦ᵣ WCap pc_p pc_b pc_e pc_a
             ∗ ▷ pc_a ↦ₐ w
             ∗ ▷ r ↦ᵣ wr
             ∗ ▷ dst ↦ᵣ w'
       }}}
         Instr Executable @ E
       {{{ RET NextIV;
           PC ↦ᵣ WCap pc_p pc_b pc_e pc_a'
           ∗ pc_a ↦ₐ w
           ∗ r ↦ᵣ wr
           ∗ dst ↦ᵣ WInt (if is_sealed wr then 1%Z else 0%Z) }}}.
   Proof.
    iIntros (Hinstr Hvpc Hpc_a ϕ) "(>HPC & >Hpc_a & >Hr & >Hdst) Hφ".
    iDestruct (map_of_regs_3 with "HPC Hr Hdst") as "[Hmap (%&%&%)]".
    iApply (wp_GetSealed with "[$Hmap Hpc_a]"); eauto; simplify_map_eq; eauto.
    by rewrite !dom_insert; set_solver+.
    iNext. iIntros (regs' retv) "(#Hspec & Hpc_a & Hmap)". iDestruct "Hspec" as %Hspec.

    destruct Hspec as [|].
    { (* Success *)
      iApply "Hφ". iFrame. incrementPC_inv; simplify_map_eq.
      rewrite (insert_commute _ PC dst) // insert_insert (insert_commute _ r dst) //
              (insert_commute _ dst PC) // insert_insert.
      iDestruct (regs_of_map_3 with "Hmap") as "(?&?&?)"; eauto; iFrame. }
    { (* Failure (contradiction) *)
      incrementPC_inv; simplify_map_eq; eauto. congruence. }
   Qed.

   Lemma wp_GetSealed_success_dst E pc_p pc_b pc_e pc_a pc_a' w dst w' :
     decodeInstrW w = GetSealed dst dst →
     isCorrectPC (WCap pc_p pc_b pc_e pc_a) →
     (pc_a + 1)%a = Some pc_a' →

       {{{ ▷ PC ↦ᵣ WCap pc_p pc_b pc_e pc_a
             ∗ ▷ pc_a ↦ₐ w
             ∗ ▷ dst ↦ᵣ w'
       }}}
         Instr Executable @ E
       {{{ RET NextIV;
           PC ↦ᵣ WCap pc_p pc_b pc_e pc_a'
           ∗ pc_a ↦ₐ w
           ∗ dst ↦ᵣ WInt (if is_sealed w' then 1%Z else 0%Z) }}}.
   Proof.
     iIntros (Hinstr Hvpc Hpca' ϕ) "(>HPC & >Hpc_a & >Hdst) Hφ".
     iDestruct (map_of_regs_2 with "HPC Hdst") as "[Hmap %]".
     iApply (wp_GetSealed with "[$Hmap Hpc_a]"); eauto; simplify_map_eq; eauto.
     by rewrite !dom_insert; set_solver+.
     iNext. iIntros (regs' retv) "(#Hspec & Hpc_a & Hmap)". iDestruct "Hspec" as %Hspec.

     destruct Hspec as [|].
     { iApply "Hφ". iFrame. incrementPC_inv; simplify_map_eq.
       rewrite (insert_commute _ PC dst) // insert_insert insert_commute // insert_insert.
       iDestruct (regs_of_map_2 with "Hmap") as "(?&?)"; eauto; iFrame. }
     { incrementPC_inv; simplify_map_eq; eauto. congruence. }
   Qed.

End cap_lang_rules.
